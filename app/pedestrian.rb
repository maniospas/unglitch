require 'app/obstacles/building.rb'


class Pedestrian
    attr_accessor :x, :y, :destroyed, :moving, :solid, :interactive, :score, :speed, :is_pedestrian, :health, :particles, :cleansing, :speedup
    def initialize(x, y, outfit, friendly)
        @x = x
        @y = y
        @destroyed = false
        @outfit = outfit
        @walk = 0
        @moving = false
        @dx = 0
        @dy = 0
        @dx_secondary = 0
        @dy_secondary = 0
        @angle = 0
        @solid = true
        @friendly = friendly
        @interactive = true
        @score = 0
        @speed = 1
        @health = 0
        @is_pedestrian = true
        @particles = []
        @cleansing = 0
        @cleansing_active = false
        @cleansing_progress = -1
        @speedup = 0
    end

    def interact(from, args)
        #if from.is_a? Pedestrian
        #    if from != args.state.player1
        #        from.score -= 1
        #        from.destroyed = true
        #        @score += 1
        #    end
        #end
    end

    def target(targetx, targety)
        if (targetx-@x).abs > (targety-@y).abs
            @dx = targetx-@x<0?-1:1
            @dy_secondary = targety-@y<0?-1:1
            @dy = 0
            @dx_secondary = 0
        else
            @dy = targety-@y<0?-1:1
            @dx_secondary = targetx-@x<0?-1:1
            @dx = 0
            @dy_secondary = 0
        end
        if (targetx-@x).abs + (targety-@y).abs < 0.5
            @dx = 0
            @dy = 0
            @dx_secondary = 0
            @dy_secondary = 0
        end
    end

    def on_fix(args)
        if @cleansing > 0 and @cleansing_active == false
            @cleansing -= 1
            @cleansing_progress = 0
            @cleansing_active = true
        end
    end

    def process(args)
        @speed = 1
        if @speedup > 0
            @speed = 1.5
            @speedup -= 0.75/60
            if @speedup < 0
                @speedup = 0
            end
        end

        collision_offset = 0.1*@speed
        collision_distance = 1.0-collision_offset/2


        if @cleansing_active
            @cleansing_progress += 1
            if @cleansing_progress > 8
                @cleansing_progress = -1
                @cleansing_active = false
            end
            args.state.obstacles.each do |b|
                if b.interactive and (b.x-@x-@dx*collision_offset).abs()<collision_distance+@cleansing_progress*1.0/8 and (b.y-@y-@dy*collision_offset).abs()<collision_distance+@cleansing_progress*1.0/8 and (b.x!=@x or b.y!=@y)
                    b.interact(self, args)
                end
            end
        end


        if @friendly > 0
            target(args.state.player1.x, args.state.player1.y)
        end
        if @friendly < 0
            moving_chance = 0.05
            if @dx !=0 or @dy != 0
                moving_chance /= 50
            end
            if rand() < moving_chance
                r = rand()
                if r < 0.25
                    @dx = -1
                    @dy = 0
                elsif r < 0.5
                    @dx = 1
                    @dy = 0
                elsif r < 0.75
                    @dx = 0
                    @dy = -1
                else
                    @dx = 0
                    @dy = 1
                end
            end
        end
        #if @friendly < 0
        #    target(args.state.player1.x, args.state.player1.y)
        #    @dx = -@dx
        #    @dy = -@dy
        #end
        if @x+@dx < 0
            @dx = 0
        end
        if @x+@dx >= args.state.width
            @dx = 0
        end
        if @y+@dy < 0
            @dy = 0
        end
        if @y+@dy >= args.state.height
            @dy = 0
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

        if @score < 0 and @destroyed == false
            building = Building.new(@x.round(), @y.round(), "building0", chance:0, contents: self)
            building.turn_to_tower(args)
            args.state.obstacles.push(building)
            @destroyed = true
            @score = 1  # prepare for when it unfreezes
        elsif @health < 0 and @destroyed == false
            @destroyed = true
        end

        if @dx == 0 and @dy == 0
            @moving = false
            args.state.obstacles.each do |b|
                if b.interactive and (b.x-@x-@dx*collision_offset).abs()<collision_distance and (b.y-@y-@dy*collision_offset).abs()<collision_distance and (b.x!=@x or b.y!=@y)
                    b.interact(self, args)
                end
            end
        else 
            @moving = true
            args.state.obstacles.each do |b|
                if b.interactive and (b.x-@x-@dx*collision_offset).abs()<collision_distance and (b.y-@y-@dy*collision_offset).abs()<collision_distance and (b.x!=@x or b.y!=@y)
                    b.interact(self, args)
                end
            end
            args.state.obstacles.each do |b|
                if b.solid and (b.x-@x-@dx*collision_offset).abs()<collision_distance and (b.y-@y-@dy*collision_offset).abs()<collision_distance and (b.x!=@x or b.y!=@y)
                    @dx = @dx_secondary
                    @dy = @dy_secondary
                    @dx_secondary = 0
                    @dy_secondary = 0
                    break
                end
            end
            if @dx != 0 or @dy != 0
                args.state.obstacles.each do |b|
                    if b.solid and (b.x-@x-@dx*collision_offset).abs()<collision_distance and (b.y-@y-@dy*collision_offset).abs()<collision_distance and (b.x!=@x or b.y!=@y)
                        @dx = 0
                        @dy = 0
                        @moving = false
                        break
                    end
                end
            end
        end


        @x += @dx*collision_offset
        @y += @dy*collision_offset

        @particles.each do |particle|
            particle.process()
        end
        if @particles.length != 0 
            @particles = @particles.reject(&:ended)
        end

        if @moving
            @walk += 1
            if @walk >= 4*5
                @walk = 0
            end
        end
    end

    def render(args)
        if @moving
            walk_progress = @walk.div(5)
            args.lowrez.sprites << {
                x: (@x- args.state.viewx)*8,
                y: (@y- args.state.viewy)*8, 
                w: 8,
                h: 8,
                path: 'sprites/pedestrian/left'+walk_progress.to_s+'.png',
                angle: @angle
            }
        else
            @walk = 0
        end
            

        args.lowrez.sprites << {
            x: (@x- args.state.viewx)*8,
            y: (@y- args.state.viewy)*8, 
            w: 8,
            h: 8,
            path: 'sprites/pedestrian/'+@outfit+'.png',
            angle: @angle
        }
    end

    def render_front(args)
        if @cleansing_progress != -1
            args.lowrez.sprites << {
                x: (@x- args.state.viewx)*8-4,
                y: (@y- args.state.viewy)*8-4, 
                w: 16,
                h: 16,
                path: 'sprites/effects/cleanse'+@cleansing_progress.div(4).to_s+'.png',
                angle: @angle
            }
        end
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