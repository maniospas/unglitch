require 'app/obstacles/building.rb'


class Pedestrian
    attr_accessor :x, :y, :destroyed, :moving, :solid, :interactive, :score, :speed, :is_pedestrian, :health, :particles, :pending_add, :cleansing, :speedup
    def initialize(x, y, friendly)
        @x = x
        @y = y
        @destroyed = false
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
        @pending_add = 0
        @acquired = 0
        @angle = 270
        @message = 0
        @message_countdown = 0
        @view_angle = @angle
        @view_angle_timer = 0

        hair_colors = [
            {r: 72, g: 88, b: 41},
            {r: 255, g: 242, b: 0},
            {r: 77, g: 57, b: 57},
            {r: 90, g: 50, b: 20},
            {r: 212, g: 212, b: 212}
        ]
        body_colors = [
            {r: 0, g: 0, b: 0},
            {r: 0, g: 64, b: 0},
            {r: 64, g: 0, b: 0},
            {r: 0, g: 0, b: 64}
        ]
        head_colors = [
            {r: 255, g: 196, b: 128}, 
            {r: 255, g: 141, b: 0}, 
            {r: 125, g: 74, b: 12},
            {r: 180, g: 103, b: 71}
        ]

        hair = hair_colors.sample
        body = body_colors.sample
        head = head_colors.sample
        @visual = [
            {path: "sprites/pedestrian/body/stand", r: body.r, g: body.g, b: body.b},
            {path: "sprites/pedestrian/head/stand", r: head.r, g: head.g, b: head.b},
            {path: "sprites/pedestrian/hair"+(rand*4).floor.to_s+"/stand", r: hair.r, g: hair.g, b: hair.b}
        ]
    end

    def message=(text)
        @message = text
        @message_countdown = 1
    end

    def message
        @message
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

    def sigz(v, vzero)
        if v < -vzero
            v = -1
        elsif v > vzero
            v = 1
        else
            v = 0
        end
        v
    end

    def onzerprev(v, vzero)
        if v == 0
            v = vzero
        end
        v
    end

    def target(targetx, targety)
        if (targetx-@x).abs > (targety-@y).abs
            @dx = sigz(targetx-@x, 0.1)
            @dy_secondary = sigz(targety-@y, 0.1)
            @dy = 0
            @dx_secondary = 0
        else
            @dy = sigz(targety-@y, 0.1)
            @dx_secondary = sigz(targetx-@x, 0.1)
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
        @acquired = 1
    end

    def process(args)
        if @acquired > 0
            @dx = 0
            @dy = 0
            @dx_secondary = 0
            @dy_secondary = 0
        end

        @speed = 1
        if @speedup > 0
            @speed = 1.5
            @speedup -= 0.75/6*args.state.dt
            if @speedup <= 0
                @speedup = 0
            end
        end

        if @message_countdown > 0
            @message_countdown -= args.state.dt*0.5
            if @message_countdown <= 0
                @message_countdown = 0
                @message = ""
            end
        end

        collision_offset = args.state.dt*@speed
        collision_distance = 1.0-collision_offset/2


        if @cleansing_active
            @cleansing_progress += args.state.dt*10
            if @cleansing_progress > 8
                @cleansing_progress = -1
                @cleansing_active = false
            end
            args.state.obstacles.each do |b|
                if b.interactive and (b.x-@x-@dx*collision_offset) ** 2 + (b.y-@y-@dy*collision_offset) ** 2<(collision_distance+@cleansing_progress*1.2/8) ** 2 and (b.x!=@x or b.y!=@y)
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

        if @dx<0
            @angle = 90
        end
        if @dx>0
            @angle = 270
        end
        if @dy<0
            @angle = 180
        end
        if @dy>0
            @angle = 0
        end

        if @angle != @view_angle
            @view_angle_timer -= 1
            if @view_angle_timer < 0
                @view_angle_timer = 2
                @view_angle = @angle
            end
        else
            @view_angle_timer = 2
            #@view_angle = @angle
        end


        @x += @dx*collision_offset
        @y += @dy*collision_offset

        @particles.each do |particle|
            particle.process()
        end
        if @particles.length != 0 
            @particles = @particles.reject(&:ended)
        end

        if @acquired > 0
            @acquired -= args.state.dt
            if @acquired < 0
                @acquired = 0
            end
        end

        if @moving
            @walk += args.state.dt*10
            if @walk >= 2*5
                @walk = 0
            end
        else
            @walk = 0
        end
    end

    def render(args)
        #if @moving
        #    walk_progress = @walk.floor().div(5)
        #    args.state.my_sprites << {
        #        x: (@x- args.state.viewx)*8,
        #        y: (@y- args.state.viewy)*8, 
        #        w: 8,
        #        h: 8,
        #        path: 'sprites/pedestrian/walk/left'+walk_progress.to_s+'.png',
        #        angle: @angle
        #    }
        #else
        #    @walk = 0
        #end

        if @acquired > 0
            args.state.my_sprites << {
                x: (@x- args.state.viewx)*8,
                y: (@y- args.state.viewy)*8, 
                w: 8,
                h: 8,
                path: 'sprites/pedestrian/shadow.png',
            }
        end

        @visual.each do |layer|
            args.state.my_sprites << {
                x: (@x- args.state.viewx)*8,
                y: (@y- args.state.viewy+0.7*(0.5-(@acquired-0.5).abs))*8, 
                w: 8,
                h: 8,
                r: layer.r,
                g: layer.g,
                b: layer.b,
                path: layer.path+@view_angle.to_s+'.png',
            }
        end
    end

    def render_front(args)
        if @cleansing_progress != -1
            args.state.my_sprites << {
                x: (@x- args.state.viewx)*8-4,
                y: (@y- args.state.viewy+0.7*(0.5-(@acquired-0.5).abs))*8-4, 
                w: 16,
                h: 16,
                path: 'sprites/effects/cleanse'+@cleansing_progress.round().div(4).to_s+'.png',
                angle: @view_angle
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