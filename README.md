# ascii2morse

|Offset|Register|Permissions|Width|Description|
|:----:|:-------|:---------:|:---:|-----------|
|```0x00```|PRESCALER|```WR```|32b|Clock divider value. Sets the duration of a ""dot"" in the Morse sequence.|
|```0x04```|STATUS|```_R```|2b|Status flags for the internal FIFO. Bit 0: Empty Bit 1: Full|
|```0x08```|ASCII_IN|```W_```|8b|Write ASCII characters to this register to push them into the FIFO.|