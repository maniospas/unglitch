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
STATE_HELP = 6

def parse_time(time)
  sec = (time/60.0).floor()
  ms = ((time/60.0-sec)*60).floor()
  if sec >= 60
    mins = sec.div(60)
    sec = sec % 60
  else
    mins = 0
  end
  if mins < 10
    mins = mins.to_s#"0"+mins.to_s
  else
    mins = mins.to_s
  end
  if sec < 10
    sec = "0"+sec.to_s
  else
    sec = sec.to_s
  end
  #if ms < 10
  #  ms = "0"+ms.to_s
  #else
  #  ms = ms.to_s
  #end
  mins+":"+sec#+":"+ms
end

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

def render_help(args)
  buttons = [
    {path: 'sprites/tile/building0.png', enabled_at: 0, text: "Nothing special."},
    {path: 'sprites/tile/granary.png', enabled_at: 1, text: "Improves next."},
    {path: 'sprites/tile/barrier.png', enabled_at: 1, text: "Don't stand over."},
    {path: 'sprites/tile/arena.png', enabled_at: 1, text: "Speedup."},
    {path: 'sprites/tile/nursery.png', enabled_at: 1, text: "Extra health."},
  ]

  args.state.main_particle.process()
  args.state.main_particle2.process()
  args.state.intro += args.state.dt*10
  args.state.my_sprites << {
        x: 0,
        y: 0, 
        w: 64,
        h: 64,
        path: 'sprites/generic.png',
        angle: 0,
  }
  args.state.my_sprites << {
      x: 0,
      y: 46 - [37-5*args.state.intro, 0].max, 
      w: 64,
      h: 16,
      path: 'sprites/logo.png',
      angle: 0,
  }

  dpx = 3
  dpy = 32

  buttons.each do |button|
    if args.state.progress >= button.enabled_at
      px = dpx
      py = dpy

      args.state.my_sprites << {
          x: px,
          y: py, 
          w: 8,
          h: 8,
          path: button.path
      }
      args.lowrez.labels << {
        x: px+10, y: py+4, 
        w: 4, h: 4,
        r:255, g: 255, b: 255, a:255,
        text: button.text,
        font: 'fonts/smol.ttf',
        size_enum: -9
      }
    else
    end
    dpy -= 10
  end

  args.state.my_sprites << {
    x: -4,
    y: -4, 
    w: 68,
    h: 68,
    a: 128,
    path: 'sprites/shadow.png'
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
  
  if (args.inputs.keyboard.key_down.enter or args.lowrez.mouse_down)
    args.state.game_state = STATE_SELECTION
  end

  # MOUSE
  args.state.main_particle.render(25, 46 - [37-5*args.state.intro, 0].max - 1, args)
  args.state.main_particle2.render(args.lowrez.mouse_position.x-4, args.lowrez.mouse_position.y-4, args)
end

def render_selection(args)
  args.state.mouse_position_prev_x ||= 0
  args.state.mouse_position_prev_y ||= 0
  mouse_moved =  args.state.mouse_position_prev_x != args.lowrez.mouse_position.x or args.lowrez.mouse_position.y != args.lowrez.mouse_position.y
  args.state.mouse_position_prev_x = args.lowrez.mouse_position.x
  args.state.mouse_position_prev_y = args.lowrez.mouse_position.y

  if args.state.all_progress.length == 0
    args.state.all_progress["best0.number"] = args.gtk.read_file("best0.number").to_i
    args.state.all_progress["best1.number"] = args.gtk.read_file("best1.number").to_i
    args.state.all_progress["best2.number"] = args.gtk.read_file("best2.number").to_i
    args.state.all_progress["best3.number"] = args.gtk.read_file("best3.number").to_i
    args.state.all_progress["best4.number"] = args.gtk.read_file("best4.number").to_i
    args.state.all_progress["best5.number"] = args.gtk.read_file("best5.number").to_i
    args.state.all_progress["best6.number"] = args.gtk.read_file("best6.number").to_i
    args.state.all_progress["best7.number"] = args.gtk.read_file("best7.number").to_i
    args.state.all_progress["best8.number"] = args.gtk.read_file("best8.number").to_i
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
      y: 46 - [37-5*args.state.intro, 0].max, 
      w: 64,
      h: 16,
      path: 'sprites/logo.png',
      angle: 0,
  }
  
  args.state.main_particle.process()
  args.state.main_particle2.process()
  #args.state.main_particle2.render(55, 41 - [23-5*args.state.intro, 0].max, args)


  buttons = [
    {path: 'data/1tutorial', difficulty: 0, spawn_rate: 1},
    {path: 'data/2town', difficulty: 0.3, spawn_rate: 1},
    {path: 'data/3town_large', difficulty: 0.4, spawn_rate: 1},
    {path: 'data/4hospital', difficulty: 0.4, spawn_rate: 0.5},
    {path: 'data/5factory', difficulty: 0.6, spawn_rate: 2},
    {path: 'data/6boss', difficulty: 0.7, spawn_rate: 0.5},
    {path: 'data/7others', difficulty: 0.85, spawn_rate: 3},
    {path: 'data/8patrols', difficulty: 0.5, spawn_rate: 1},
    {path: 'data/9final', difficulty: 0.7, spawn_rate: 1},
  ]
  args.state.selected_progress ||= 0
  progress = 0
  bpx = 6
  bpy = 33
  delay = 50

  if args.inputs.keyboard.key_down.left
    args.state.selected_progress -= 1
    if args.state.selected_progress == -1
      args.state.selected_progress = 0
    elsif args.state.selected_progress == 2
      args.state.selected_progress = 3
    elsif args.state.selected_progress == 5
      args.state.selected_progress = 6
    elsif args.state.volume > 0
      args.outputs.sounds << 'sounds/Select.ogg'
    end
  end
  if args.inputs.keyboard.key_down.right
    args.state.selected_progress += 1
    if args.state.selected_progress == 6
      args.state.selected_progress = 5
    elsif args.state.selected_progress == 3
      args.state.selected_progress = 2
    elsif args.state.selected_progress == 6
      args.state.selected_progress = 5
    elsif args.state.volume > 0
      args.outputs.sounds << 'sounds/Select.ogg'
    end
  end
  if args.inputs.keyboard.key_down.up and args.state.selected_progress >= 3
    args.state.selected_progress -= 3
    if args.state.volume > 0
      args.outputs.sounds << 'sounds/Select.ogg'
    end
  end
  if args.inputs.keyboard.key_down.down and args.state.selected_progress < 6
    args.state.selected_progress += 3
    if args.state.volume > 0
      args.outputs.sounds << 'sounds/Select.ogg'
    end
  end

  buttons.each do |button|
    if args.state.progress >= progress
      shrink = (250+delay-args.state.intro*8 >= 0)
      shrink = shrink ? 6 : 0
      px = bpx
      py = bpy - [250+delay-args.state.intro*8, 0].max
      mouse_true_over = (args.lowrez.mouse_position.x>=px and args.lowrez.mouse_position.x<=px+16 and args.lowrez.mouse_position.y>=py and args.lowrez.mouse_position.y<=py+10) and args.state.game_state == STATE_SELECTION
      if mouse_true_over and mouse_moved
        if args.state.selected_progress != progress and args.state.volume > 0
          args.outputs.sounds << 'sounds/Select.ogg'
        end
        args.state.selected_progress = progress
      end
      mouse_over = args.state.selected_progress == progress and mouse_moved==false
      color = (mouse_over==true)? 255 : 128
      args.state.button_rotate ||= {}
      args.state.button_rotate_global ||= -1
      if mouse_over and args.state.button_rotate_global == -1
        args.state.button_rotate_global = progress
      end
      if mouse_over and args.state.button_rotate_global == progress
        args.state.button_rotate[progress] = [args.state.button_rotate[progress].to_f + args.state.dt*40, 30].min
      else
        args.state.button_rotate[progress] = [args.state.button_rotate[progress].to_f - args.state.dt*40, 0].max
      end
      if args.state.button_rotate[progress].to_f == 0 and args.state.button_rotate_global == progress
        args.state.button_rotate_global = -1
      end
      if args.state.button_rotate[progress].to_f < 15
        args.state.my_sprites << {
          x: px+16/2-16/2*(1-args.state.button_rotate[progress]/15.0)+shrink/2,
          y: py, 
          w: 16*(1-args.state.button_rotate[progress]/15.0)-shrink,
          h: 10,
          r: color,
          g: color,
          b: color,
          path: button.path+'.png',
          angle: 0
        }
      else
        args.state.my_sprites << {
          x: px+16/2-16/2*(args.state.button_rotate[progress]/15.0-1)+shrink/2,
          y: py, 
          w: 16*(args.state.button_rotate[progress]/15.0-1)-shrink,
          h: 10,
          r: color,
          g: color,
          b: color,
          path: 'data/blank.png',
          angle: 0
        }
      end
      if (args.lowrez.mouse_down and mouse_true_over) or (args.inputs.keyboard.key_down.enter and mouse_over) 
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

      if args.state.button_rotate[progress].to_f == 30
        score = args.state.all_progress["best"+progress.to_s+".number"].to_i
        if score == 0
          score = "---"
        else
          score = parse_time(score)
        end
        
        args.lowrez.labels << {
          x: px+1, y: py+4, 
          w: 4, h: 4,
          r:232, g:232, b:32, a:255,
          text: score,
          font: 'fonts/smol.ttf',
          size_enum: -9
        }
        args.state.my_sprites << {
          x: px+2, y: py+7, 
          w: 5, h: 5,
          path: 'sprites/controls/clock0.png',
        }
      end
    end
    progress += 1
    bpx += 18
    delay += 50
    if progress == 3 or progress == 6
      bpx = 6
      bpy -= 12
    end
  end
  args.state.my_sprites << {
    x: -4,
    y: -4, 
    w: 68,
    h: 68,
    a: 128,
    path: 'sprites/shadow.png'
  }
  ## HELP
  #px = 2
  #py = 1
  #mouse_over = (args.lowrez.mouse_position.x>=px and args.lowrez.mouse_position.x<=px+7 and args.lowrez.mouse_position.y>=py and args.lowrez.mouse_position.y<=py+5)
  #color = (mouse_over==true)?255 : 128
  #args.state.my_sprites << {
  #  x: px,
  #  y: py, 
  #  w: 7,
  #  h: 7,
  #  r: color,
  #  g: color,
  #  b: color,
  #  path: 'sprites/controls/help.png',
  #  angle: 0
  #}
  #if args.lowrez.mouse_down and mouse_over
  ##end

  # SOUND
  px = 64-7-1
  py = 1
  mouse_over = (args.lowrez.mouse_position.x>=px and args.lowrez.mouse_position.x<=px+7 and args.lowrez.mouse_position.y>=py and args.lowrez.mouse_position.y<=py+5)
  color = (mouse_over==true)?255 : 128
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

  
  # TFX
  px = 64-7-1-9-1
  py = 1
  mouse_over = (args.lowrez.mouse_position.x>=px and args.lowrez.mouse_position.x<=px+8 and args.lowrez.mouse_position.y>=py and args.lowrez.mouse_position.y<=py+5)
  color = (mouse_over==true)?255 : 128
  args.state.my_sprites << {
    x: px,
    y: py, 
    w: 8,
    h: 7,
    r: color,
    g: color,
    b: color,
    path: args.state.tfx==0? 'sprites/controls/notfx.png' : 'sprites/controls/tfx.png',
    angle: 0
  }
  if args.lowrez.mouse_down and mouse_over
    args.gtk.write_file("tfx.number", args.state.tfx.to_s)
    args.state.tfx = 1-args.state.tfx
  end



  # MOUSE
  args.state.main_particle.render(25, 46 - [37-5*args.state.intro, 0].max - 1, args)
  args.state.main_particle2.render(args.lowrez.mouse_position.x-4, args.lowrez.mouse_position.y-4, args)
end

def tick args
  #args.gtk.hide_cursor
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
  args.state.tfx ||= 1-args.gtk.read_file("tfx.number").to_i
  args.state.tutorial ||= 0
  args.state.progress ||= args.gtk.read_file("progress.number").to_i
  args.state.pending_progress ||= args.state.progress
  args.state.shake ||= 0
  args.state.wait_while_dead ||= 0
  args.state.time ||= 0
  args.state.transition ||= 0
  args.state.shake_dampening ||= 0.7
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
    args.state.player1 = Pedestrian.new(2, 6, 0)
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
          #if rand() < 0.15
          #  args.state.obstacles.push(Building.new(width, height, 'grass', solid: false))
          #else
          characters.push(Pedestrian.new(width, height, -1))
          #end
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
    
    #if args.state.volume > 0
    #  args.outputs.sounds << 'sounds/Entering.ogg'
    #end
  end

  if args.state.game_state == STATE_START
    args.state.start_time ||= Time.now.to_f
    if Time.now.to_f == args.state.start_time
      args.outputs.sounds << 'sounds/Intro.ogg'
    end
    args.state.main_particle ||= VictoryParticle.new()
    args.state.main_particle2 ||= LightningParticle.new()
    elapsed = (Time.now.to_f-args.state.start_time)*2
    if elapsed < 2
      args.state.my_sprites << {
        x: 0,
        y: 0, 
        w: 64,
        h: 64,
        path: 'sprites/start0.png',
      }  
      args.state.my_sprites << {
        x: -4,
        y: -4, 
        w: 68,
        h: 68,
        a: 255.0,
        r: 0,
        g: 0,
        b: 0,
        path: :pixel
      }
      args.state.my_sprites << {
        x: -4,
        y: -4, 
        w: 68,
        h: 68,
        a: 255,
        path: 'sprites/shadow.png'
      }
      args.state.main_particle.process()
      args.state.main_particle.render(25, 24, args)
      finalize(args)
      return
    end
    if elapsed < 3
      args.state.my_sprites << {
        x: 0,
        y: 0, 
        w: 64,
        h: 64,
        path: 'sprites/start0.png',
      }  
      args.state.my_sprites << {
        x: -4,
        y: -4, 
        w: 68,
        h: 68,
        a: 255.0*(3-elapsed),
        r: 0,
        g: 0,
        b: 0,
        path: :pixel
      }
      args.state.my_sprites << {
        x: -4,
        y: -4, 
        w: 68,
        h: 68,
        a: 255,
        path: 'sprites/shadow.png'
      }
      args.state.main_particle.process()
      args.state.main_particle.render(25, 24, args)
      finalize(args)
      return
    end
    if elapsed < 5
      elapsed -= 3
      elapsed /= 2
      args.state.my_sprites << {
        x: 0,
        y: 0, 
        w: 64,
        h: 64,
        path: 'sprites/start0.png',
      }  
      args.state.my_sprites << {
        x: -4,
        y: -4, 
        w: 68,
        h: 68,
        a: 128+128*(1-elapsed),
        path: 'sprites/shadow.png'
      }
      args.state.main_particle.process()
      args.state.main_particle.render(25, 24, args)
      finalize(args)
      return
    end
    args.state.my_sprites << {
      x: 0,
      y: 0, 
      w: 64,
      h: 64,
      path: 'sprites/start.png',
    }
    if elapsed >= 6
      args.state.my_sprites << {
          x: 32-8/2,
          y: 2, 
          w: 8,
          h: 8,
          path: 'sprites/controls/enter.png',
      }
    end
    args.state.my_sprites << {
      x: -4,
      y: -4, 
      w: 68,
      h: 68,
      a: 128,
      path: 'sprites/shadow.png'
    }
    args.state.main_particle.process()
    args.state.main_particle.render(25, 24, args)
    if elapsed < 6
      args.state.main_particle2.process()
      args.state.main_particle2.render(25+30*[elapsed-5, 1].min, 24, args)
      args.state.main_particle2.render(25-22*[elapsed-5, 1].min, 24, args)
    end

    if args.inputs.keyboard.key_down.enter or args.lowrez.mouse_down and elapsed >= 6
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
  
  if args.state.game_state == STATE_HELP
    render_help(args)
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
      path: (Time.now.to_f*7).round() % 3!=0? 'sprites/gameover.png': 'sprites/generic.png',
      angle: 0
    }
    args.state.my_sprites << {
      x: -4,
      y: -4, 
      w: 68,
      h: 68,
      a: 128,
      path: 'sprites/shadow.png'
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
      path: (Time.now.to_f*7).round() % 3!=0? 'sprites/victory.png': 'sprites/generic.png',
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
        original_message = "Time "+parse_time(args.state.current_score)+"#New record!"
        message = original_message[0..[original_message.length-1, args.state.game_over_progress.round().div(2)].min]
        args.lowrez.labels << {
          x: 15, y: 28, 
          w: 4, h: 4,
          r:255, g:255, b:255, a:255,
          text: message.split("#")[0],
          font: 'fonts/smol.ttf',
          size_enum: -9
        }
        args.lowrez.labels << {
          x: 15, y: 22, 
          w: 4, h: 4,
          r:128, g:255, b:0, a:255,
          text: message.split("#")[1],
          font: 'fonts/smol.ttf',
          size_enum: -9
        }
      else
        original_message = "Time "+parse_time(args.state.current_score)+"#Best "+parse_time(best_score)
        message = original_message[0..[original_message.length-1, args.state.game_over_progress.round().div(2)].min]
        args.lowrez.labels << {
          x: 15, y: 28, 
          w: 4, h: 4,
          r:255, g:255, b:255, a:255,
          text: message.split("#")[0],
          font: 'fonts/smol.ttf',
          size_enum: -9
        }
        args.lowrez.labels << {
          x: 15, y: 22, 
          w: 4, h: 4,
          r:255, g:255, b:255, a:255,
          text: message.split("#")[1],
          font: 'fonts/smol.ttf',
          size_enum: -9
        }
      end

      args.state.my_sprites << {
        x: -4,
        y: -4, 
        w: 68,
        h: 68,
        a: 128,
        path: 'sprites/shadow.png'
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

  dx = 0
  dy = 0
  
  if args.inputs.keyboard.key_held.left# or args.inputs.key_held.A or args.inputs.key_held.a
    dx -= 2
  end
  if args.inputs.keyboard.key_held.right# or args.inputs.key_held.D or args.inputs.key_held.d
    dx += 2
  end
  if args.inputs.keyboard.key_held.up# or args.inputs.key_held.W or args.inputs.key_held.w
    dy += 2
  end
  if args.inputs.keyboard.key_held.down# or args.inputs.key_held.S or args.inputs.key_held.s
    dy -= 2
  end

  if dx != 0 or dy != 0
    args.state.player1.target((args.state.player1.x+dx).round, (args.state.player1.y+dy).round)
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
        a: 128+128.0/15*transition,
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
    if args.state.wait_while_dead == 0
      if args.state.volume > 0
        args.outputs.sounds << 'sounds/Leaving.ogg'
      end
    end
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
    else
      args.audio[:music].gain = args.state.volume*0.5*(1-args.state.wait_while_dead/60.0)
    end
  end

  if args.state.player1.score >= 10
    args.state.wait_while_dead += args.state.dt*10
    if args.state.current_score == 0
      args.state.current_score = args.state.time.round()
      if args.state.volume > 0
        args.outputs.sounds << 'sounds/Leaving.ogg'
      end
    end
    if args.state.wait_while_dead > 60
      args.state.wait_while_dead = 0
      args.state.game_state = STATE_VICTORY
      best_score_path = "best"+((args.state.pending_progress-1).to_s)+".number"
      
      best_score = args.state.all_progress[best_score_path].to_f#args.gtk.read_file(best_score_path).to_i
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
    else
      args.audio[:music].gain = args.state.volume*0.5*(1-args.state.wait_while_dead/60.0)
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
  elsif args.state.player1.score + args.state.player1.health == 0 and args.state.player1.destroyed == false
    tutorial = "Careful!"
  end
  args.state.prev_tutorial ||= ""
  if args.state.prev_tutorial != tutorial
    args.state.game_over_progress = 0
    if tutorial.length > 0 and args.state.volume > 0
      args.outputs.sounds << 'sounds/Typewritter.ogg'
    end
  end
  args.state.prev_tutorial = tutorial


  if args.state.tutorial > 0 and args.state.player1.score < 10
    args.state.time += args.state.dt*10
    args.state.my_sprites << {
      x: 0, y: 63-5, 
      w: 5, h: 5,
      path: 'sprites/controls/clock'+((args.state.time*8/60.0).floor() % 8).to_s+'.png',
    }
    
    args.lowrez.labels << {
      x: 6, y: 62, 
      w: 4, h: 4,
      r:232, g:232, b:32, a:255,
      text: parse_time(args.state.time),
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
      x: 64-6,
      y: 7, 
      w: 8,
      h: 8,
      r:255,
      g:255,
      b:255,
      a:255,
      text: args.state.player1.score.to_s,
      font: 'fonts/smol.ttf',
      size_enum: -9
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

  
  if args.state.player1.message.length!=0 and args.state.tfx > 0
    args.lowrez.labels << {
      x: 34-args.state.player1.message.length/2, y: 44, 
      w: 4, h: 4,
      r:255, g:255, b:255, a:164,
      text: args.state.player1.message,
      font: 'fonts/smol.ttf',
      size_enum: -9
    }
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