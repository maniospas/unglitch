require 'app/projectile.rb'
require 'app/particle.rb'


class Building
    attr_accessor :x, :y, :destroyed, :solid, :interactive, :contents, :is_pedestrian
    def initialize(x, y, texture, angle: 0, glitched: 0, vp: 0, height: 8, solid: true, chance: 1, contents: nil)
        @x = x
        @y = y
        @destroyed = false
        @solid = solid
        @texture = texture
        @interactive = false
        @size = glitched != 0 ? 0.5 : 8
        @angle = angle
        @glitched = glitched
        @vp = vp
        @height = height
        @chance = chance
        @particles = []
        @contents = contents
        @is_pedestrian = false
        @type_chance = 1
    end

    def turn_to_vp(args) 
        @prevtexture = @texture
        @prevsolid = @solid
        @interactive = true
        @glitched = 1
        @solid = true
        @texture = "vp"
        @vp = 1
        @particles.push(VictoryParticle.new())
        @type_chance *= 2
    end

    def turn_to_tower(args) 
        @prevtexture = @texture
        @prevsolid = @solid
        @interactive = true
        @glitched = 1
        @solid = true
        @texture = "tower"
        @countdown = 30
        @vp = 0
        @particles.push(Particle.new())
        @type_chance *= 0.4
    end
    
    def process(args)
        if @texture == "nursery" or @texture == "factory" or @texture == "arena"
            @interactive = true
        end
        if @texture == "tower"
            @countdown -= 1
            if @countdown < 0
                @countdown = 60
                proj = Projectile.new(@x-0.5, @y, -1, 0, self)
                args.state.obstacles.push(proj)
                proj.process(args)
                proj = Projectile.new(@x+0.5, @y, 1, 0, self)
                args.state.obstacles.push(proj)
                proj.process(args)
                proj = Projectile.new(@x, @y-0.5, 0, -1, self)
                proj.process(args)
                args.state.obstacles.push(proj)
                proj = Projectile.new(@x, @y+0.5, 0, +1, self)
                args.state.obstacles.push(proj)
                proj.process(args)
            end
        end
        spawn_rate = 0.001*@chance*args.state.spawn_rate
        if args.state.tutorial == 1
            spawn_rate *= 100
        end
        if rand()<spawn_rate and @vp == 0 and @texture!="bush" and @texture!="tower" and @texture!=nil
            if args.state.tutorial == 1
                args.state.tutorial = 2
                turn_to_vp(args)
            elsif args.state.tutorial <= 2
                
            elsif rand() > args.state.difficulty*@type_chance or @texture == "granary"
                turn_to_vp(args)
            else
                turn_to_tower(args)
            end 
        end
        
        @particles.each do |particle|
            particle.process()
        end
        if @particles.length != 0 
            @particles = @particles.reject(&:ended)
            if @particles.length == 0 
                @texture = @prevtexture
            end
        end
    end
    
    def interact(from, args)
        if from.is_pedestrian and @texture == "arena"
            if from.speedup == 0 #and args.state.tutorial > 2
                from.speedup = 3
                args.state.tutorial = 3
                from.particles.push(CleansingParticle.new())
                if from == args.state.player1 and args.state.volume > 0
                    args.outputs.sounds << 'sounds/Buff2.ogg'
                end
            end
        elsif from.is_pedestrian and @texture == "factory"
            if from.cleansing < 1 #and args.state.tutorial > 2
                from.cleansing = 1
                args.state.tutorial = 3
                from.particles.push(CleansingParticle.new())
                if from == args.state.player1 and args.state.volume > 0
                    args.outputs.sounds << 'sounds/Buff2.ogg'
                end
            end
        elsif from.is_pedestrian and @texture == "nursery"
            if from.health < 1 #and args.state.tutorial > 2
                from.health += 1
                args.state.tutorial = 3
                from.particles.push(HealParticle.new())
                if from == args.state.player1 and args.state.volume > 0
                    args.outputs.sounds << 'sounds/Buff.ogg'
                end
            end
        elsif from.is_pedestrian and from != contents and @texture!=nil
            if from != args.state.player1 and args.state.tutorial == 2
                args.state.tutorial = 1
            end
            if from == args.state.player1 and args.state.volume > 0
                if @texture == "tower"
                    args.outputs.sounds << 'sounds/Destroy.ogg'
                else
                    args.outputs.sounds << 'sounds/Fix.ogg'
                end
            end
            from.score += @vp
            @interactive = false
            @glitched = 0
            @vp = 0
            from.on_fix(args)
            if @contents != nil
                @destroyed = true
                @contents.destroyed = false
                @contents.x = @x
                @contents.y = @y
                args.state.obstacles.push(@contents)
            else
                @solid = @prevsolid
                @texture = nil
                @particles = [Explosion.new()]
            end
        end
    end

    def render(args)
        if @texture != nil
            args.lowrez.sprites << {
                x: (@x- args.state.viewx)*8+(8-@size)/2,
                y: (@y- args.state.viewy)*8+(8-@size)/2, 
                w: @size,
                h: @size/8*@height,
                path: 'sprites/tile/'+@texture+'.png',
                angle: @angle
            }
        end
    end

    def render_front(args)
        @particles.each do |particle|
            particle.render((@x- args.state.viewx)*8, 
                            (@y- args.state.viewy)*8,
                            args)
        end
        0
    end

    def rect(args)
        [@x,@y,1,1]
    end
end