require 'app/particle.rb'



class Projectile
    attr_accessor :x, :y, :destroyed, :moving, :solid, :interactive, :is_pedestrian
    def initialize(x, y, dx, dy, creator)
        @x = x
        @y = y
        @dx = dx
        @dy = dy
        @solid = false
        @interactive = false
        @destroyed = false
        @walk = 0
        @is_pedestrian = false
        @particles = [LightningParticle.new()]
        @creator = creator
        @speed = 0.5
    end

    def process(args)
        if @x+@dx < 0
            @dx = 0
            @destroyed = true
        end
        if @x+@dx >= args.state.width
            @dx = 0
            @destroyed = true
        end
        if @y+@dy < 0
            @dy = 0
            @destroyed = true
        end
        if @y+@dy >= args.state.height
            @dy = 0
            @destroyed = true
        end
        if @dx<0
            @angle = 90
        end
        if @dx>0
            @angle = -90
        end
        if @dy<0
            @angle = 180
        end
        if @dy>0
            @angle = 0
        end

        args.state.obstacles.each do |b|
            if b.solid and (b.x-@x-@dx*@speed*args.state.dt).abs()<0.5 and (b.y-@y-@dy*@speed*args.state.dt).abs()<0.5 and (b.x!=@x or b.y!=@y) and @creator != b and not b.is_a? Particle #and b.is_pedestrian
                if b.is_pedestrian and b.speedup > 0
                    next
                end
                @destroyed = true
                if b.is_pedestrian
                    b.particles.push(Blood.new())
                    if b == args.state.player1 and args.state.volume > 0
                        args.outputs.sounds << 'sounds/Hit.ogg'
                    end
                    if b.health > 0
                        b.health -= 1
                    else
                        b.score -= 1
                    end
                end
            end
        end

        @x += @dx*@speed*args.state.dt
        @y += @dy*@speed*args.state.dt

        @particles.each do |particle|
            particle.process()
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

    def render(args)
        @walk += 1
        if @walk >= 5*3
            @walk = 0
        end
        walk_progress = @walk.round().div(3)
        args.state.my_sprites << {
            x: (@x- args.state.viewx)*8,
            y: (@y- args.state.viewy)*8, 
            w: 8,
            h: 8,
            path: 'sprites/effects/lightning'+walk_progress.to_s+'.png',
            angle: @angle
        }
    end

    def rect(args)
        [@x,@y,1,1]
    end
end


class Laser < Projectile
    def initialize(x, y, dx, dy, creator)
        super(x, y, dx, dy, creator)
        @particles = []
        @speed = 1.5
    end
    def render(args)
        args.state.my_sprites << {
            x: (@x- args.state.viewx)*8,
            y: (@y- args.state.viewy)*8, 
            w: 8,
            h: 8,
            path: 'sprites/effects/laser.png',
            angle: @angle
        }
    end
end