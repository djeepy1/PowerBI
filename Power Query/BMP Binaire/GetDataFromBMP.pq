let
    Source = File.Contents(filename),
    headerformat = BinaryFormat.Record([
        bmptype = BinaryFormat.Text(2),
        filesize = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
        reserved = BinaryFormat.Binary(4),
        imageoffset = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
        headersize = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
        imagewidth = BinaryFormat.ByteOrder(BinaryFormat.SignedInteger32, ByteOrder.LittleEndian),
        imageheight = BinaryFormat.ByteOrder(BinaryFormat.SignedInteger32, ByteOrder.LittleEndian),
        planes = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16, ByteOrder.LittleEndian),
        colordepth = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger16, ByteOrder.LittleEndian),
        compressionmode = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
        imagesize = BinaryFormat.ByteOrder(BinaryFormat.UnsignedInteger32, ByteOrder.LittleEndian),
        XpixPerMeter = BinaryFormat.ByteOrder(BinaryFormat.SignedInteger32, ByteOrder.LittleEndian),
        YpixPerMeter = BinaryFormat.ByteOrder(BinaryFormat.SignedInteger32, ByteOrder.LittleEndian),
        colorscount = BinaryFormat.ByteOrder(BinaryFormat.SignedInteger32, ByteOrder.LittleEndian),
        importantcolors = BinaryFormat.ByteOrder(BinaryFormat.SignedInteger32, ByteOrder.LittleEndian)
    ]),
    binaryformat = BinaryFormat.Choice(headerformat, 
        each BinaryFormat.Record([
            Header = _,
            palette = BinaryFormat.Transform(
                BinaryFormat.Binary(_[filesize] - _[imagesize] - 14 - 40),
                (x) => Binary.ToList(x)
            ),
            image = 
                BinaryFormat.Transform(
                BinaryFormat.Binary(_[imagesize]),
                (x) => Binary.ToList(x)
            )
        ])),
    imagestruct = binaryformat(Source),
	
	imagesize = imagestruct[Header][imagesize],
	imagewidth = imagestruct[Header][imagewidth],
	imageheight = imagestruct[Header][imageheight],
	colordepth = imagestruct[Header][colordepth],
	offsetrows = Number.IntegerDivide(imagesize,imageheight),
	bytes_per_row = Number.RoundUp ( (imagewidth * colordepth) / 8 ),
    
	bmprows = List.Generate(() => 0, each _ < imagesize, each _ + offsetrows, (x) => List.Range(imagestruct[image], x, bytes_per_row)),
	
    expandrow8 = (row) => 
        List.Range(
            List.Accumulate(
                row, 
                {},
                (state, current) => List.Combine({state, List.Repeat({current}, 8/colordepth)})
            ),
            0,
            imagewidth
        ),
    expandrow24 = (row) => 
        List.Transform(
            List.Split(row, colordepth/8),
            (pixellist) => List.Accumulate(
                    pixellist, 
                    0,
                    (state, current) => Number.BitwiseShiftLeft(state, 8) + current)
        ),
    expandrow = (row) =>
        if colordepth <= 8 then expandrow8(row)
        else expandrow24(row),


    pixels = List.Transform(bmprows, expandrow),
	
	
	#"Converti en table" = Table.FromList(pixels, Splitter.SplitByNothing(), {"PixelRaw"}, null, ExtraValues.Error),
    #"Add RowId" = Table.AddIndexColumn(#"Converti en table", "RowId", 1, 1, Int64.Type),
    #"Expand Rows" = Table.ExpandListColumn(#"Add RowId", "PixelRaw"),
    #"Type PixelRaw" = Table.TransformColumnTypes(#"Expand Rows",{{"PixelRaw", Int64.Type}}),
    #"Add PixelId" = Table.AddIndexColumn(#"Type PixelRaw", "PixelId", 1, 1, Int64.Type),
    #"Compute ColumnId" = Table.AddColumn(#"Add PixelId", "ColumnId", each Number.Mod([PixelId]-1, imagewidth)+1, Int64.Type),
        // if Number.Mod([PixelId], imagewidth) = 0 then imagewidth else Number.Mod([PixelId], imagewidth) , type number),
    #"Compute Mask" = Table.AddColumn(#"Compute ColumnId", "BitMask", each Number.Mod([ColumnId]-1, 8/colordepth)+1, Int64.Type),

    GetRGB = (value as number) as text => 
        let            
            v = Number.BitwiseXor(value, 16777215),
            R = Number.ToText(Number.BitwiseShiftRight(Number.BitwiseAnd(v, 16711680), 16), "X"),
            G = Number.ToText(Number.BitwiseShiftRight(Number.BitwiseAnd(v, 65280), 8), "X"),
            B = Number.ToText(Number.BitwiseAnd(v, 255), "X"),
            RGB = 
                if colordepth = 1 and value = 1 then "000000" 
                else if colordepth = 4 and value > 1 then "000000" 
                else if colordepth = 8 and value = 1 then Number.ToText(v, "X") & Number.ToText(v, "X") & Number.ToText(v, "X")
                else  R & G & B
        in
            RGB,

    ApplyBitmask1 = (bitmask as number, value as number) => 
        /* 0 = white ; 1 = black (inverse de la valeur hexa) */
        if bitmask=1 then (if Number.BitwiseAnd(value, 128)=128 then 0 else 1)
        else if bitmask=2 then (if Number.BitwiseAnd(value, 64)=64 then 0 else 1)
        else if bitmask=3 then (if Number.BitwiseAnd(value, 32)=32 then 0 else 1)
        else if bitmask=4 then (if Number.BitwiseAnd(value, 16)=16 then 0 else 1)
        else if bitmask=5 then (if Number.BitwiseAnd(value, 8)=8 then 0 else 1)
        else if bitmask=6 then (if Number.BitwiseAnd(value, 4)=4 then 0 else 1)
        else if bitmask=7 then (if Number.BitwiseAnd(value, 2)=2 then 0 else 1)
        else if bitmask=8 then (if Number.BitwiseAnd(value, 1)=1 then 0 else 1) else 0,
    ApplyBitmask4 = (bitmask as number, value as number) => 
        if bitmask=1 then Number.BitwiseShiftRight(Number.BitwiseAnd(Number.BitwiseNot(value), 240), 4)
        else if bitmask=2 then Number.BitwiseAnd(Number.BitwiseNot(value), 15) else 0,
    ApplyBitmask8 = (bitmask as number, value as number) => Number.BitwiseNot(value),
    ApplyBitmask8up = (bitmask as number, value as number) => Number.BitwiseXor(value, 16777215),
    ApplyBitmaskDefault = (bitmask as number, value as number) => value,
    ApplyBitmask = (bitmask as number, value as number) => 
        if colordepth = 1 then ApplyBitmask1(bitmask, value)
        else if colordepth = 4 then ApplyBitmask4(bitmask, value)
        else if colordepth = 8 then ApplyBitmask8(bitmask, value)
        else if colordepth > 8 then ApplyBitmask8up(bitmask, value)
        else 0,

    #"Compute PixelValue" = Table.AddColumn(#"Compute Mask", "PixelValue", each ApplyBitmask([BitMask], [PixelRaw]), Int64.Type),
    #"Compute Latitude" = Table.AddColumn(#"Compute PixelValue", "latitude", each base_latitude + [RowId]*step_latitude, type number),
    #"Compute Longitude" = Table.AddColumn(#"Compute Latitude", "longitude", each base_longitude + [ColumnId]*step_longitude, type number),
    Arrondi = Table.TransformColumns(#"Compute Longitude",{{"longitude", each Number.Round(_, precision_longitude), type number}, {"latitude", each Number.Round(_, precision_latitude), type number}}),
    #"Personnalisée ajoutée" = Table.AddColumn(Arrondi, "RGB", each "#" & GetRGB([PixelValue]), type text)
in
    #"Personnalisée ajoutée"