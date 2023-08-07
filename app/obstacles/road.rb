require 'app/particle.rb'
require 'app/obstacles/road.rb'


class Laserjet
    attr_accessor :x, :y, :destroyed, :solid, :interactive, :is_pedestrian, :texture
    def initialize(x, y)
        @x = x
        @y = y
        @texture = 'laserjet'
        @size = 8
        @progress = (rand()*90).to_i
        @solid = true
        @interactive = false
        @is_pedestrian = false
        @destroyed = false
        @particles = []
    end

    def interact(from, args)
    end
    
    def render(args)
        if @texture != nil
            args.lowrez.sprites << {
                x: (@x- args.state.viewx)*8+(8-@size)/2,
                y: (@y- args.state.viewy)*8+(8-@size)/2, 
                w: @size,
                h: @size,
                path: 'sprites/tile/'+@texture+'.png',
                angle: 0
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

    
    def process(args)
        @progress += 1
        if @progress > 90
            @progress = 0
            proj = Laser.new(@x-0.5, @y, -1, 0, self)
            args.state.obstacles.push(proj)
            proj.process(args)
            proj = Laser.new(@x+0.5, @y, 1, 0, self)
            args.state.obstacles.push(proj)
            proj.process(args)
            proj = Laser.new(@x, @y-0.5, 0, -1, self)
            proj.process(args)
            args.state.obstacles.push(proj)
            proj = Laser.new(@x, @y+0.5, 0, +1, self)
            args.state.obstacles.push(proj)
            proj.process(args)
        end
        
        if @progress > 90-20 or @progress < 10
            @texture = 'laserjet'
        else 
            @texture = 'laserjet1'
        end

        @particles.each do |particle|
            particle.process()
        end
        @particles = @particles.reject(&:ended)

    end
end



class Barrier
    attr_accessor :x, :y, :destroyed, :solid, :interactive, :is_pedestrian, :texture
    def initialize(x, y)
        @x = x
        @y = y
        @texture = 'barrier'
        @size = 8
        @progress = (rand()*30).to_i
        @solid = true
        @interactive = false
        @is_pedestrian = false
        @destroyed = false
        @particles = [LightningExplosion.new()]
    end

    def interact(from, args)
    end
    
    def render(args)
        if @texture != nil
            args.lowrez.sprites << {
                x: (@x- args.state.viewx)*8+(8-@size)/2,
                y: (@y- args.state.viewy)*8+(8-@size)/2, 
                w: @size,
                h: @size,
                path: 'sprites/tile/'+@texture+'.png',
                angle: 0
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

    
    def process(args)
        if @solid
            @progress += 1
            if @progress > 30
                @texture = 'nobarrier'
                @progress = 0
                @solid = false
            elsif @progress > 26
                @texture = 'barrier1'
            elsif @progress > 24
                @texture = 'barrier2'
            end
        end
        if @solid == false
            @progress += 1
            if @progress > 30
                @texture = 'barrier'
                @solid = true
                @progress = 0
                @particles.push(LightningExplosion.new())
                args.state.obstacles.each do |b|
                    if b.solid and (b.x-@x).abs()<0.5 and (b.y-@y).abs()<0.5 and b.is_pedestrian
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
            elsif @progress > 26
                @texture = 'barrier2'
            elsif @progress > 24
                @texture = 'barrier1'
            end
        end

        @particles.each do |particle|
            particle.process()
        end
        @particles = @particles.reject(&:ended)

    end
end
