
VdpPort.Vram:		EQU $dc01
VdpPort.Read:		EQU $dc02
VdpPort.Write:		EQU $dc03

VdpCommandData:		EQU $dc06
VdpCommandData.SX:	EQU $dc06
VdpCommandData.SY:	EQU $dc08
VdpCommandData.DX:	EQU $dc0a
VdpCommandData.DY:	EQU $dc0c
VdpCommandData.NX:	EQU $dc0e
VdpCommandData.NY:	EQU $dc10
VdpCommandData.CMD:	EQU $dc15
VdpCommandData.ARG:	EQU $dc16	; CMD / ARG swapped positions

FrameCounter:		EQU $dc1d
