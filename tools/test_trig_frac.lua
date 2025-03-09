test_complete_callback = 0x7feeee

function test_smul_frac()
	emu.log("emu!")
	factorone = emu.read16(0x00, emu.memType.snesMemory, true)
	factortwo = emu.read16(0x02, emu.memType.snesMemory, true)
	
	product = emu.read16(0x04, emu.memType.snesMemory, true)
	
	real_product = math.ceil((factorone * factortwo) / 256) & 0xffff
	if ((real_product ~= product)) then
		emu.log(factorone .. "*" .. factortwo .. "/256 = " .. real_product .. ", not " .. product)
	end
end

emu.addMemoryCallback(test_smul_frac, emu.callbackType.write, test_complete_callback)