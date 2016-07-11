function beep()
    if beep_enabled then
        pwm.setup(5,200,512)
        pwm.start(5)
        tmr.delay(5000000)
        pwm.stop(5)
    end
end
