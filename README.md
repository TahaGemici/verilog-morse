# ascii2morse

|Offset|Register|Permissions|Description|
|:----:|:-------|:---------:|-----------|
|```0x00```|PRESCALER|```WR```|Clock divider value. Sets the duration of a ""dot"" in the Morse sequence.|
|```0x04```|STATUS|```_R```|Status flags for the internal FIFO.<br>STATUS[0]: Empty<br>STATUS[1]: Full<br>STATUS[31:2]: _ignored_|
|```0x08```|ASCII_IN|```W_```|Write ASCII characters to this register to push them into the FIFO.<br>ASCII_IN[7:0]: ASCII Character<br>ASCII_IN[31:8]: _ignored_|