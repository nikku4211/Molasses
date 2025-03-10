test_complete_callback = 0x7feeee

function test_trig_frac()
	emu.log("emu!")
	angle = emu.read(0x00, emu.memType.snesMemory, true)
    sfsin = emu.read16(0x01, emu.memType.snesMemory, true)
    sfcos = emu.read16(0x03, emu.memType.snesMemory, true)
	
	real_sin = math.floor(math.sin(angle * 2 * math.pi/256)*256)
    real_cos = math.floor(math.cos(angle * 2 * math.pi/256)*256)
    
	if ((real_sin ~= sfsin) or (real_cos ~= sfcos)) then
		emu.log("sin(" .. angle .. ") * 256 = " .. real_sin .. ", not " .. sfsin)
        emu.log("cos(" .. angle .. ") * 256 = " .. real_cos .. ", not " .. sfcos)
	end
end

emu.addMemoryCallback(test_trig_frac, emu.callbackType.write, test_complete_callback)