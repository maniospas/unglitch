require 'app/lowrez.rb' 
require 'app/obstacles/road.rb'
require 'app/obstacles/building.rb'
require 'app/pedestrian.rb'

STATE_CREATION = 0
STATE_START = 1
STATE_PLAYING = 2
STATE_GAMEOVER = 3
STATE_VICTORY = 4
STATE_SELECTION = 5

def finalize(args)
  time = Time.now.to_f
  dt = (time - $timer_start)*6
  if dt > 0.2
    dt = 0.2
  end
  args.state.dt ||= dt
  args.state.dt = args.state.dt*0.9 + dt*0.1
  args.lowrez.sprites << args.state.my_sprites
  $timer_start = Time.now.to_f
end

def render_selection(args)
  if args.state.all_progress.length == 0
    args.state.all_progress["best0.number"] = args.gtk.read_file("best0.number").to_i
    args.state.all_progress["best1.number"] = args.gtk.read_file("best1.number").to_i
    args.state.all_progress["best2.number"] = args.gtk.read_file("best2.number").to_i
    args.state.all_progress["best3.number"] = args.gtk.read_file("best3.number").to_i
    args.state.all_progress["best4.number"] = args.gtk.read_file("best4.number").to_i
    args.state.all_progress["best5.number"] = args.gtk.read_file("best5.number").to_i
  end

  args.state.my_sprites << {
        x: 0,
        y: 0, 
        w: 64,
        h: 64,
        path: 'sprites/generic.png',
        angle: 0,
  }
    
  args.state.intro += args.state.dt*10
  
  args.state.my_sprites << {
      x: 0,
      y: 45 - [20-5*args.state.intro, 0].max, 
      w: 64,
      h: 16,
      path: 'sprites/logo.png',
      angle: 0,
  }

  buttons = [
    {path: 'data/tutorial', difficulty: 0, spawn_rate: 1},
    {path: 'data/town', difficulty: 0.3, spawn_rate: 1},
    {path: 'data/town_large', difficulty: 0.4, spawn_rate: 1},
    {path: 'data/hospital', difficulty: 0.4, spawn_rate: 0.5},
    {path: 'data/factory', difficulty: 0.7, spawn_rate: 0.5}
  ]

  progress = 0
  bpx = 6
  bpy = 26
  delay = 50
  buttons.each do |button|
    if args.state.progress >= progress
      px = bpx
      py = bpy - [250+delay-args.state.intro*5, 0].max
      mouse_over = (args.lowrez.mouse_position.x>=px and args.lowrez.mouse_position.x<=px+16 and args.lowrez.mouse_position.y>=py and args.lowrez.mouse_position.y<=py+16)
      mouse_over = mouse_over and args.state.game_state == STATE_SELECTION
      color = (mouse_over==true)? 255 : 212
      args.state.my_sprites << {
        x: px,
        y: py, 
        w: 16,
        h: 16,
        r: color,
        g: color,
        b: color,
        path: button.path+'.png',
        angle: 0
      }
      if args.lowrez.mouse_down and mouse_over
        args.state.path = button.path+".txt"
        args.state.game_state = STATE_CREATION
        args.state.difficulty = button.difficulty
        args.state.spawn_rate = button.spawn_rate
        args.state.pending_progress = progress+1
        args.state.prevtotalscore = 0
        args.state.shake = 0
        args.state.shakex = 0
        args.state.shakey = 0
        args.state.transition = 0
      end

      if mouse_over
        score = args.state.all_progress["best"+progress.to_s+".number"].to_i
        if score == 0
          score = "_"
        else
          score = ((score*1.0/60).round()).to_s
        end
        
        args.lowrez.labels << {
          x: px+6, y: py+4, 
          w: 4, h: 4,
          r:232, g:232, b:32, a:255,
          text: score,
          font: 'fonts/smol.ttf',
          size_enum: -9
        }
        args.state.my_sprites << {
          x: px, y: py, 
          w: 5, h: 5,
          path: 'sprites/controls/clock_partial.png',
        }
      end
    end
    progress += 1
    bpx += 18
    delay += 50
    if progress == 3
      bpx = 6
      bpy -= 18
    end
  end

  # SOUND
  px = 64-7-1
  py = 1
  mouse_over = (args.lowrez.mouse_position.x>=px and args.lowrez.mouse_position.x<=px+7 and args.lowrez.mouse_position.y>=py and args.lowrez.mouse_position.y<=py+5)
  color = (mouse_over==true)?255 : 212
  args.state.my_sprites << {
    x: px,
    y: py, 
    w: 7,
    h: 7,
    r: color,
    g: color,
    b: color,
    path: args.state.volume==0? 'sprites/controls/mute.png' : 'sprites/controls/sound.png',
    angle: 0
  }
  if args.lowrez.mouse_down and mouse_over
    args.gtk.write_file("mute.number", args.state.volume.to_s)
    args.state.volume = 1-args.state.volume
    args.audio[:music].gain = args.state.volume*0.5
  end
end

def tick args
  $timer_start ||= Time.now.to_f
  args.state.my_sprites = []
  # initialize
  args.state.all_progress ||= {}
  args.state.obstacles ||= []
  args.state.game_state ||= STATE_START
  args.state.player1 ||= nil
  args.state.width ||= 16
  args.state.height ||= 16  
  args.state.viewx = 4
  args.state.viewy = 4
  args.state.volume ||= 1-args.gtk.read_file("mute.number").to_i
  args.state.tutorial ||= 0
  args.state.progress ||= args.gtk.read_file("progress.number").to_i
  args.state.pending_progress ||= args.state.progress
  args.state.shake ||= 0
  args.state.wait_while_dead ||= 0
  args.state.time ||= 0
  args.state.transition ||= 0
  #args.gtk.set_window_fullscreen(true)

  if !args.inputs.keyboard.has_focus && args.state.tick_count != 0
    if args.audio[:music]!=nil
      args.audio[:music].gain  = 0
    end
    args.state.my_sprites << {
      x: 0,
      y: 0, 
      w: 64,
      h: 64,
      path: 'sprites/start.png',
      angle: 0
    }
    args.lowrez.labels << {
      x: 4, y: 26, 
      w: 4, h: 4,
      r:255, g:255, b:255, a:255,
      text: "Paused",
      font: 'fonts/smol.ttf',
      size_enum: -9
    }
    flicker = 0
    args.state.my_sprites << {
        x: 32-8/2-flicker/2,
        y: 2-flicker/2, 
        w: 8+flicker,
        h: 8+flicker,
        path: 'sprites/controls/enter.png',
        angle: 0
    }
    finalize(args)
    return
  elsif args.audio[:music]!=nil
    args.audio[:music].gain  = args.state.volume*0.5
  #  args.audio[:music].paused = false
  end

  if args.state.game_state == STATE_CREATION
    args.state.tutorial = 0
    args.state.player1 = Pedestrian.new(2, 6, 'pedestrian'+rand(4).to_s, 0)
    args.state.obstacles = []
    args.state.height = 0
    args.state.width = 0
    prev = nil
    characters = []
    countlines = 0
    path = args.state.path
    args.gtk.read_file(path).split("\n").each do |line|
      countlines += 1
    end
    args.gtk.read_file(path).split("\n").each do |line|
      width = 0
      height = countlines-args.state.height
      line.each_char do |c|
        if c == '*'
          args.state.obstacles.push(Building.new(width, height, 'bush'))
        end
        #if c == '|'
        #  args.state.obstacles.push(Road.new(width, height, 0, angle: 90))
        #end
        #if c == '-'
        #  args.state.obstacles.push(Road.new(width, height, 0, angle: 0))
        #end
        if c == '-'
          if rand() < 0.15
            args.state.obstacles.push(Building.new(width, height, 'grass', solid: false))
          end
        end
        if c == 'O'
          if rand() < 0.15
            args.state.obstacles.push(Building.new(width, height, 'grass', solid: false))
          else
            characters.push(Pedestrian.new(width, height, 'pedestrian'+rand(4).to_s, -1))
          end
        end
        if c == 'C'
          building = Building.new(width, height, 'grass', solid: false)
          building.turn_to_vp(args)
          args.state.obstacles.push(building)
        end
        if c == 'W'
          args.state.obstacles.push(Building.new(width, height, 'building0'))
        end
        if c == 'F'
          args.state.obstacles.push(Building.new(width, height, 'factory'))
        end
        if c == 'A'
          args.state.obstacles.push(Building.new(width, height, 'arena'))
        end
        if c == 'B'
          args.state.obstacles.push(Barrier.new(width, height))
        end
        if c == 'H'
          args.state.obstacles.push(Building.new(width, height, 'nursery'))
        end
        if c == 'G'
          args.state.obstacles.push(Building.new(width, height, 'granary'))
        end
        if c == 'T'
          args.state.obstacles.push(Laserjet.new(width, height))
        end
        if c == 'M'
          args.state.obstacles.push(Building.new(width, height, 'building0', chance: 0))
        end
        if c == 'P'
          args.state.player1.x = width
          args.state.player1.y = height
        end
        prev = c
        width += 1
      end
      if width > args.state.width
        args.state.width = width
      end
      args.state.height += 1
    end
    args.state.obstacles.push(args.state.player1)
    characters.each do |character|
      args.state.obstacles.push(character)
    end
    args.state.game_state = STATE_PLAYING
  end

  if args.state.game_state == STATE_START
    args.state.my_sprites << {
      x: 0,
      y: 0, 
      w: 64,
      h: 64,
      path: 'sprites/start.png',
      angle: 0
    }
    flicker = 0
    args.state.my_sprites << {
        x: 32-8/2-flicker/2,
        y: 2-flicker/2, 
        w: 8+flicker,
        h: 8+flicker,
        path: 'sprites/controls/enter.png',
        angle: 0
    }

    if args.inputs.keyboard.key_down.enter or args.lowrez.mouse_down
      args.state.game_state = STATE_SELECTION
      args.state.intro = 0
      args.audio.delete :music
      args.audio[:music] = {
        input: 'sounds/Main.ogg',
        gain: args.state.volume*0.5,
        looping: true
      }
    end
    finalize(args)
    return
  end
  
  if args.state.game_state == STATE_SELECTION
    render_selection(args)
    finalize(args)
    return
  end

  if args.state.game_state == STATE_GAMEOVER
    
    args.state.game_over_progress += args.state.dt*10

    original_message = "Player glitch  "
    message = original_message[0..[original_message.length-1, args.state.game_over_progress.round().div(2)].min]

    
    args.lowrez.labels << {
      x: 10, y: 26, 
      w: 4, h: 4,
      r:255, g:255, b:255, a:255,
      text: message,
      font: 'fonts/smol.ttf',
      size_enum: -9
    }


    args.state.my_sprites << {
      x: 0,
      y: 0, 
      w: 64,
      h: 64,
      path: 'sprites/gameover.png',
      angle: 0
    }
    if message.length == original_message.length
      flicker = 0
      args.state.my_sprites << {
          x: 32-8/2-flicker/2,
          y: 2-flicker/2, 
          w: 8+flicker,
          h: 8+flicker,
          path: 'sprites/controls/enter.png',
          angle: 0
      }
    end
    if (args.inputs.keyboard.key_down.enter or args.lowrez.mouse_down) and message.length == original_message.length
      args.state.game_state = STATE_SELECTION
      args.state.intro = 0
      args.audio.delete :music
      args.audio[:music] = {
        input: 'sounds/Main.ogg',
        gain: args.state.volume*0.5,
        looping: true
      }
    end
    finalize(args)
    return
  end

  if args.state.game_state == STATE_VICTORY
    args.state.game_over_progress += args.state.dt*10
    args.state.my_sprites << {
      x: 0,
      y: 0, 
      w: 64,
      h: 64,
      path: 'sprites/victory.png',
      angle: 0
    }

    original_message = ""#"Fixed 10 glitches  "
    message = original_message[0..[original_message.length-1, args.state.game_over_progress.round().div(2)].min]
    args.lowrez.labels << {
      x: 4, y: 26, 
      w: 4, h: 4,
      r:255, g:255, b:255, a:255,
      text: message,
      font: 'fonts/smol.ttf',
      size_enum: -9
    }

    best_score_path = "best"+((args.state.pending_progress-1).to_s)+".number"
    best_score = args.gtk.read_file(best_score_path).to_i
    if args.state.game_over_progress.round().div(2)-original_message.length >= 1
      if args.state.current_score <= best_score or best_score == 0
        original_message = "New best time: "+((args.state.current_score*1.0/60).round()).to_s
        message = original_message[0..[original_message.length-1, args.state.game_over_progress.round().div(2)].min]
        args.lowrez.labels << {
          x: 4, y: 26, 
          w: 4, h: 4,
          r:255, g:255, b:36, a:255,
          text: message,
          font: 'fonts/smol.ttf',
          size_enum: -9
        }
      else
        original_message = "Time: "+((args.state.current_score*1.0/60).round()).to_s+"  Best: "+((best_score*1.0/60).round()).to_s+""
        message = original_message[0..[original_message.length-1, args.state.game_over_progress.round().div(2)].min]
        args.lowrez.labels << {
          x: 4, y: 26, 
          w: 4, h: 4,
          r:168, g:64, b:64, a:255,
          text: message,
          font: 'fonts/smol.ttf',
          size_enum: -9
        }
      end
      if message.length == original_message.length
        flicker = 0
        args.state.my_sprites << {
            x: 32-8/2-flicker/2,
            y: 2-flicker/2, 
            w: 8+flicker,
            h: 8+flicker,
            path: 'sprites/controls/enter.png',
            angle: 0
        }
      end
    end
    if (args.inputs.keyboard.key_down.enter or args.lowrez.mouse_down) and message.length == original_message.length
      args.state.game_state = STATE_SELECTION
      args.state.intro = 0
      args.audio.delete :music
      args.audio[:music] = {  
        input: 'sounds/Main.ogg',
        gain: args.state.volume*0.5,
        looping: true
      }
    end
    finalize(args)
    return
  end

  args.state.mouse_pressed ||= false

  if args.inputs.keyboard.key_held.escape
    #args.state.game_state = STATE_SELECTION
    #  args.state.intro = 0
    #  args.state.player1.health = 0
      args.state.player1.score = -1
    #  args.audio.delete :music
    #  args.audio[:music] = {
    #    input: 'sounds/Main.ogg',
    #    gain: args.state.volume*0.5,
    #    looping: true
    #  }
  end

  if args.inputs.keyboard.key_held.left
    args.state.player1.target(args.state.player1.x-2, args.state.player1.y)
    if args.state.tutorial == 0
      args.state.tutorial = 1
      args.state.time = 0
      args.state.current_score = 0
    end
  end
  if args.inputs.keyboard.key_held.right
    args.state.player1.target(args.state.player1.x+2, args.state.player1.y)
    if args.state.tutorial == 0
      args.state.tutorial = 1
      args.state.time = 0
      args.state.current_score = 0
    end
  end
  if args.inputs.keyboard.key_held.down
    args.state.player1.target(args.state.player1.x, args.state.player1.y-2)
    if args.state.tutorial == 0
      args.state.tutorial = 1
      args.state.time = 0
      args.state.current_score = 0
    end
  end
  if args.inputs.keyboard.key_held.up
    args.state.player1.target(args.state.player1.x, args.state.player1.y+2)
    if args.state.tutorial == 0
      args.state.tutorial = 1
      args.state.time = 0
      args.state.current_score = 0
    end
  end
  if args.lowrez.mouse_up or args.inputs.keyboard.key_up.up or args.inputs.keyboard.key_up.down or args.inputs.keyboard.key_up.right or args.inputs.keyboard.key_up.left 
    args.state.player1.target(args.state.player1.x, args.state.player1.y)
    args.state.mouse_pressed = false
  end
  if args.lowrez.mouse_down
    args.state.mouse_pressed = true
  end

  if args.state.mouse_pressed 
    x = (args.lowrez.mouse_position.x - 32)/8
    y = (args.lowrez.mouse_position.y - 32)/8
    args.state.player1.target(args.state.player1.x+x, args.state.player1.y+y)
    if args.state.tutorial == 0
      args.state.tutorial = 1
      args.state.time = 0
      args.state.current_score = 0
    end
  end

  args.state.shake_dampening ||= 0.7
  args.state.shakex ||= 0
  args.state.shakey ||= 0
  if args.state.player1.health+args.state.player1.score < args.state.prevtotalscore or args.state.player1.destroyed
    args.state.shake = 1.0
    args.state.shakex = 0
    args.state.shakey = 0
    args.state.shake_dampening = 0.7
    if args.state.volume > 0 and args.state.player1.health+args.state.player1.score < args.state.prevtotalscore
      args.outputs.sounds << 'sounds/Hit.wav'
    end
  #  args.state.shake = 1.0
  #  args.state.shakex = 0
  #  args.state.shakey = 0
  #  args.state.shake_dampening = 0.9
  end
  args.state.prevtotalscore = args.state.player1.health+args.state.player1.score
  if args.state.shake > 0
    args.state.shakex = args.state.shakex*args.state.shake_dampening+(1-args.state.shake_dampening)*(args.state.shake/2-1)**2 *(rand()*2-1)
    args.state.shakey = args.state.shakey*args.state.shake_dampening+(1-args.state.shake_dampening)*(args.state.shake/2-1)**2 *(rand()*2-1)
    args.state.shake -= 0.07*args.state.dt*10
    if args.state.shake_dampening > 0.8
      args.state.shake -= 0.07*args.state.dt*10
    end
    if args.state.player1.destroyed and args.state.shake < 0.5
      args.state.shake += 0.07*args.state.dt*10
    end
  else
    args.state.shakex = args.state.shakex*args.state.shake_dampening
    args.state.shakey = args.state.shakey*args.state.shake_dampening
  end

  args.state.viewx = args.state.player1.x-4+args.state.shakex
  args.state.viewy = args.state.player1.y-4+args.state.shakey

  args.state.transition += args.state.dt*10
  transition = args.state.transition

  if transition < 15
    render_selection(args)
    args.state.my_sprites << {
        x: -2-args.state.shakex,
        y: -2-args.state.shakey, 
        w: 68,
        h: 68,
        a: 255.0/15*transition,
        path: 'sprites/shadow.png'
    }
    finalize(args)
    return
  elsif transition<30
    transition -= 15
    args.state.my_sprites << {
        x: 0,
        y: 0, 
        w: 64,
        h: 64,
        r: 0, g: 0, b: 0,
        a: (255-255.0/15*transition),
        path: :pixel
    }
    args.state.my_sprites << {
        x: -2-args.state.shakex,
        y: -2-args.state.shakey, 
        w: 68,
        h: 68,
        path: 'sprites/shadow.png'
    }
  end
  transition -= 30



  # render
  args.state.my_sprites << {
      x: 0,
      y: 0, 
      w: 64,
      h: 64,
      path: 'sprites/background.png',
      angle: 0
  }

  

  if transition > 30 and args.state.wait_while_dead == 0
    args.state.obstacles.each do |b|
      b.process(args)
    end
  end

  args.state.obstacles = args.state.obstacles.reject(&:destroyed)
  
  args.state.obstacles.each do |b|
    if b.x-args.state.viewx > -1 and b.y-args.state.viewy > -1 and b.x-args.state.viewx < 9 and b.y-args.state.viewy < 9
      b.render(args)
    end
  end

  if args.state.wait_while_dead > 0
    args.state.my_sprites << {
        x: 0,
        y: 0, 
        w: 64,
        h: 64,
        r: 0,
        g: 0,
        b: 0,
        a: (255.0/50*args.state.wait_while_dead),
        path: :pixel,
        angle: 0
    }
  elsif transition < 30
    args.state.my_sprites << {
        x: 0,
        y: 0, 
        w: 64,
        h: 64,
        r: 0,
        g: 0,
        b: 0,
        a: (255-255.0/30*transition),
        path: :pixel,
        angle: 0
    }
  end
  args.state.my_sprites << {
      x: -2-args.state.shakex,
      y: -2-args.state.shakey, 
      w: 68,
      h: 68,
      path: 'sprites/shadow.png',
      angle: 0
  }
  if transition < 30
    finalize(args)
    return
  end
  
  args.state.obstacles.each do |b|
    if b.x-args.state.viewx > -1 and b.y-args.state.viewy > -1 and b.x-args.state.viewx < 9 and b.y-args.state.viewy < 9
      b.render_front(args)
    end
  end

  if args.state.player1.destroyed
    args.state.wait_while_dead += args.state.dt*10
    if args.state.wait_while_dead > 60
      args.state.wait_while_dead = 0
      args.state.game_over_progress = 0
      args.state.game_state = STATE_GAMEOVER
      args.audio.delete :music
      args.audio[:music] = {
        input: 'sounds/Defeat.ogg',
        gain: args.state.volume*0.3,
        looping: true
      }
    end
  end

  if args.state.player1.score >= 10
    args.state.wait_while_dead += args.state.dt*10
    if args.state.current_score == 0
      args.state.current_score = args.state.time.round()
    end
    if args.state.wait_while_dead > 60
      args.state.wait_while_dead = 0
      args.state.game_state = STATE_VICTORY
      best_score_path = "best"+((args.state.pending_progress-1).to_s)+".number"
      
      best_score = args.state.all_progress[best_score_path]#args.gtk.read_file(best_score_path).to_i
      if best_score == 0 or args.state.current_score < best_score
        args.state.all_progress[best_score_path] = args.state.current_score
        args.gtk.write_file(best_score_path, args.state.current_score.to_s)
      end
      args.state.game_over_progress = 0
      if args.state.progress < args.state.pending_progress
        args.state.progress = args.state.pending_progress
        args.gtk.write_file("progress.number", args.state.progress.to_s)
      end
      args.audio.delete :music
      args.audio[:music] = {
        input: 'sounds/Victory.ogg',
        gain: args.state.volume*0.5,
        looping: true
      }
    end
  end

  tutorial = ""
  if args.state.tutorial==0
    tutorial = "Press mouse: run"
  elsif args.state.tutorial<=2 # building progresses the tutorial from stage 1 to 2
    tutorial = "Fix 10 glitches"
    if args.state.player1.score > 0
      args.state.tutorial = 3
    end
  elsif args.state.player1.score + args.state.player1.health == 0
    tutorial = "Careful!"
  end
  args.state.prev_tutorial ||= ""
  if args.state.prev_tutorial != tutorial
    args.state.game_over_progress = 0
  end
  args.state.prev_tutorial = tutorial


  if args.state.tutorial > 0 and args.state.player1.score < 10
    args.state.time += args.state.dt*10
    args.state.my_sprites << {
      x: 0, y: 63-5, 
      w: 5, h: 5,
      path: 'sprites/controls/clock'+((args.state.time*8/60.0).round() % 8).to_s+'.png',
    }
    
    args.lowrez.labels << {
      x: 6, y: 62, 
      w: 4, h: 4,
      r:232, g:232, b:32, a:255,
      text: ((args.state.time/60.0).round()).to_s,
      font: 'fonts/smol.ttf',
      size_enum: -9
    }
  end


  if tutorial.length > 0
    args.state.game_over_progress += args.state.dt*10
    tutorial = tutorial[0, [tutorial.length, args.state.game_over_progress.round().div(2)].min]
    args.state.my_sprites << {
        x: 1,
        y: 2, 
        w: 62,
        h: 8,
        path: 'sprites/banner.png',
        angle: 0
    }
    args.lowrez.labels << {
      x: 3, y: 7, 
      w: 4, h: 4,
      r:255, g:255, b:255, a:255,
      text: tutorial,
      font: 'fonts/smol.ttf',
      size_enum: -9
    }
  end

  args.state.score_rotate ||= 0
  args.state.prev_score ||= 0
  if args.state.prev_score < args.state.player1.score
    args.state.score_rotate = 20
  end
  if args.state.score_rotate > 0
    args.state.score_rotate -= args.state.dt*20
    if args.state.score_rotate < 0
      args.state.score_rotate = 0
    end
  end
  args.state.prev_score = args.state.player1.score

  if args.state.tutorial > 0 and args.state.player1.destroyed == false and args.state.player1.score < 10
    args.state.my_sprites << {
        x: 64-9,
        y: 2, 
        w: 8,
        h: 8,
        path: 'sprites/controls/score.png',
        angle: args.state.score_rotate*90/20
    }
    args.lowrez.labels << {
      x: 64-7,
      y: 7, 
      w: 8,
      h: 8,
      r:255,
      g:255,
      b:255,
      a:255,
      text: args.state.player1.score.to_s,
      font: 'fonts/lowrez.ttf',
      size_enum: LOWREZ_FONT_SM
    }
  end

  px = 64-9

  if args.state.tutorial > 2 and args.state.player1.pending_add > 0 and args.state.player1.score < 10 and args.state.player1.destroyed==false
    for i in 1..args.state.player1.pending_add
      px -= 7
      args.state.my_sprites << {
          x: px,
          y: 2, 
          w: 8,
          h: 8,
          path: 'sprites/controls/pending.png',
          angle: 0
      }
    end
  end
  
  if args.state.tutorial > 2 and args.state.player1.health > 0 and args.state.player1.score < 10 and args.state.player1.destroyed==false
    for i in 1..args.state.player1.health
      px -= 9
      args.state.my_sprites << {
          x: px,
          y: 2, 
          w: 8,
          h: 8,
          path: 'sprites/controls/health.png',
          angle: 0
      }
    end
  end

  if args.state.tutorial > 2 and args.state.player1.cleansing > 0 and args.state.player1.score < 10 and args.state.player1.destroyed==false
    for i in 1..args.state.player1.cleansing
      px -= 9
      args.state.my_sprites << {
          x: px,
          y: 2, 
          w: 8,
          h: 8,
          path: 'sprites/controls/cleanse.png',
          angle: 0
      }
    end
  end
  
  if args.state.tutorial > 2 and args.state.player1.speedup > 0 and args.state.player1.score < 10 and args.state.player1.destroyed==false
    for i in 1..(args.state.player1.speedup).ceil()
      args.state.my_sprites << {
          x: 64-9,
          y: 2+4*(i-1)+9, 
          w: 8,
          h: 4,
          path: 'sprites/controls/speed.png',
          angle: 0
      }
    end
  end
  
  finalize(args)
end

$gtk.reset