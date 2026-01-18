local addonInfo, privateVars = ...

---------- init namespace ---------

if not LibEKL then LibEKL = {} end
if not LibEKL.Zip then LibEKL.Zip = {} end

---------- library public function block ---------

function LibEKL.Zip.Compress (data)

	local zippedData = zlib.deflate(zlib.BEST_COMPRESSION)(data, "finish")
	local encodedData = LibEKL.Zip.EncodeBase64(zippedData)
	
	return LibEKL.Zip.Checksum(encodedData), encodedData
	
end 

function LibEKL.Zip.Uncompress (zippedData)

	local decodedData = LibEKL.Zip.DecodeBase64(zippedData)
	local data, eof = zlib.inflate()(decodedData)
	
	return data
	
end 

function LibEKL.Zip.Checksum(data)

	local checksum = Utility.Storage.Checksum(data)
	local shortCheck = string.sub(checksum, -6)
	
	local bytes = {}
	for hexPair in shortCheck:gmatch("(%x%x)") do
    	table.insert(bytes, string.char(tonumber(hexPair, 16)))
	end
	
	return LibEKL.Zip.EncodeBase64(table.concat(bytes))
	
end
