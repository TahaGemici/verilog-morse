# ascii2morse

|Offset|Name|Access|Width|Description|
|:----:|:---|:----:|:---:|-----------|
|0x00|PRESCALER|```WR```|32|Clock divider value. Sets the duration of a ""dot"" in the Morse sequence.|
|0x04|STATUS|```_R```|2|Status flags for the internal FIFO. Bit 0: Empty Bit 1: Full|
|0x08|ASCII_IN|```W_```|8|Write ASCII characters to this register to push them into the FIFO.|