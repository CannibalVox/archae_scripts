class_name HDRConverter

static func _write_rgbe8888(buffer: Array, index: int, c: Color):
	var maxChannel = max(c.r, max(c.g, c.b))
	
	var exponent = max(-128, floor(log(maxChannel) / log(2.0))) + 128
	var maxSignificand = floor(maxChannel / pow(2.0, exponent-127-8) + 0.5)
	
	if maxSignificand < 0 || maxSignificand >= 256:
		exponent = exponent + 1

	var significandDivisor = pow(2.0, exponent-127-8)
	
	var redSignificand = floor(c.r / significandDivisor + 0.5)
	var greenSignificand = floor(c.g / significandDivisor + 0.5)
	var blueSignificand = floor(c.b / significandDivisor + 0.5)
	var outputExponent = exponent
	
	buffer[index] = int(redSignificand)
	buffer[index+1] = int(greenSignificand)
	buffer[index+2] = int(blueSignificand)
	buffer[index+3] = int(outputExponent)

static func image_to_hdr(image: Image, targetPath: String) -> int:
	var hdrFile = File.new()
	var err = hdrFile.open(targetPath, File.WRITE)
	if err != OK:
		return err 
		
	var width = image.get_width()
	var height = image.get_height()
	
	hdrFile.store_line("#?RADIANCE")
	hdrFile.store_line("FORMAT=32-bit_rle_rgbe")
	hdrFile.store_line("")
	hdrFile.store_line("-Y %d +X %d" % [height, width])
	
	var buffer = []
	buffer.resize(height*width*4)
	image.lock()
	var index = 0
	for y in height:
		for x in width:
			var c = image.get_pixel(x, y)
			if y == 0 && x == 0:
					print("PIXEL 0: %f %f %f " % [c.r, c.g, c.b])
			_write_rgbe8888(buffer, index, c)
			index += 4
	image.unlock()
	
	hdrFile.store_buffer(PoolByteArray(buffer))
	hdrFile.close()
	return OK
