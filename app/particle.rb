class OneParticle
    attr_accessor :x, :y, :energy, :dx, :dy, :dead
    def initialize(x, y, dx, dy, energy)
        @x = x
        @y = y
        @energy = energy
        @dx = dx
        @dy = dy
        @dead = false
    end
    def process()
        @x += dx
        @y += dy
        @energy -= 0.1
        if @energy < 0
            @dead = true
        end
    end
end

    

class Particle
    def initialize()
        @particles = []
    end

    def create_particle()
        OneParticle.new(3+rand(), 5+rand()*2, 0, 0.2-0.1*rand(), 4-rand())
    end

    def rate()
        0.2
    end

    def r(energy)
        255
    end

    def g(energy)
        255
    end

    def b(energy)
        255
    end

    def a(energy)
        (196*energy/4).round()
    end

    def process()
        @particles.each do |particle|
            particle.process()
        end
        if rand() < rate()
            @particles.push(create_particle())
        end
        @particles = @particles.reject(&:dead)
    end

    def render(x, y, args)
        @particles.each do |particle|
            args.state.my_sprites << {
                x: x+particle.x,
                y: y+particle.y, 
                w: 1,
                h: 1,
                r: r(particle.energy),
                g: g(particle.energy),
                b: b(particle.energy),
                a: a(particle.energy),
                path: :pixel
            }
        end
    end

    def ended()
        false
    end
end




class VictoryParticle < Particle
    def create_particle()
        OneParticle.new(2+rand()*3, 3+rand()*2, 0, (0.2-0.1*rand())*3, 4-rand())
    end

    def rate()
        0.5
    end

    def r(energy)
        163
    end

    def g(energy)
        0
    end

    def b(energy)
        164
    end

    def a(energy)
        (196*energy/4).round()
    end
end



class LightningParticle < Particle
    def create_particle()
        OneParticle.new(2+rand()*3, 3+rand()*2, (0.1-0.2*rand())*3, (0.1-0.2*rand())*3, 2-rand()*0.5)
    end
    
    def process()
        @particles.each do |particle|
            particle.process()
            if rand() < 0.1
                particle.dx += (0.1-0.2*rand())
                particle.dy += (0.1-0.2*rand())
            end
        end
    end

    def rate()
        0.5
    end

    def r(energy)
        255
    end

    def g(energy)
        255
    end

    def b(energy)
        (255*(energy/2)).round()
    end

    def a(energy)
        (196*energy/2).round()
    end
end


class LightningExplosion < Particle
    def initialize()
        super()
        for i in 1..10 do
            @particles.push(create_particle())
        end
    end
    
    def process()
        @particles.each do |particle|
            particle.process()
            if rand() < 0.1
                particle.dx += (0.1-0.2*rand())
                particle.dy += (0.1-0.2*rand())
            end
        end
    end

    def rate()
        0
    end
    
    def create_particle()
        OneParticle.new(3+rand(), 6, (0.1-0.2*rand())*3, (0.1-0.2*rand())*3, 2-rand()*0.5)
    end

    def r(energy)
        255
    end

    def g(energy)
        255
    end

    def b(energy)
        (255*(energy/2)).round()
    end

    def a(energy)
        (196*energy/2).round()
    end
    
    def ended()
        @particles.length == 0
    end
end



class HealParticle < Particle
    def initialize()
        super()
        for i in 1..50 do
            @particles.push(create_particle())
        end
    end

    def create_particle()
        OneParticle.new(2+rand()*3, 3+rand()*2, (0.1-0.2*rand())*3, (0.1-0.2*rand())*3, 2-rand()*0.5)
    end

    def rate()
        0
    end

    def r(energy)
        (128*(1-energy/2)).round()
    end

    def g(energy)
        255
    end

    def b(energy)
        (128*(1-energy/2)).round()
    end

    def a(energy)
        (196*energy/2).round()
    end
end



class CleansingParticle < Particle
    def initialize()
        super()
        for i in 1..10 do
            @particles.push(create_particle())
        end
    end

    def create_particle()
        OneParticle.new(2+rand()*3, 3+rand()*2, (0.1-0.2*rand())*3, (0.1-0.2*rand())*3, 2-rand()*0.5)
    end

    def rate()
        0
    end

    def r(energy)
        (128*(energy/2)+64).round()
    end

    def g(energy)
        (128*(energy/2)+64).round()
    end

    def b(energy)
        255
    end

    def a(energy)
        255#(255*energy/2).round()
    end
end



class Explosion < Particle
    def initialize()
        super()
        for i in 1..50 do
            @particles.push(create_particle())
        end
    end

    def rate()
        0
    end
    
    def create_particle()
        OneParticle.new(2+rand()*3, 3+rand()*2, (0.1-0.2*rand())*3, (0.1-0.15*rand())*4, 2-rand()*0.5)
    end

    def r(energy)
        30
    end

    def g(energy)
        8
    end

    def b(energy)
        64
    end

    def a(energy)
        (196*energy/2).round()
    end
    
    def ended()
        @particles.length == 0
    end
end


class Blood < Particle
    def initialize()
        super()
        for i in 1..10 do
            @particles.push(create_particle())
        end
    end

    def rate()
        0
    end
    
    def create_particle()
        OneParticle.new(2+rand()*4, 2+rand()*4, (0.1-0.2*rand())*5, (0.1-0.2*rand())*5, 1-rand()*0.25)
    end

    def r(energy)
        255#(128+128*energy/4).round()
    end

    def g(energy)
        64
    end

    def b(energy)
        64
    end

    def a(energy)
        (128+128*energy).round()
    end
    
    def ended()
        @particles.length == 0
    end
end