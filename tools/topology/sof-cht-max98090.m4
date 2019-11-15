#
# Topology for generic CHT/BSW board with Maxim 98090 codec
#

# Include topology builder
include(`utils.m4')
include(`dai.m4')
include(`pipeline.m4')
include(`ssp.m4')

# Include TLV library
include(`common/tlv.m4')

# Include Token library
include(`sof/tokens.m4')

# Include Cherrytrail DSP configuration
include(`platform/intel/cht.m4')

#
# Define the pipelines
#
# PCM0 ----> volume ---------------+
#                                  |--low latency mixer ----> volume ---->  SSP2
# PCM1 -----> volume ----> SRC ----+
#
# PCM0 <---- Volume <---- SSP2
#

# Low Latency playback pipeline 1 on PCM 0 using max 2 channels of s32le.
# 1000us deadline on core 0 with priority 1
PIPELINE_PCM_ADD(sof/pipe-low-latency-playback.m4,
	1, 0, 2, s32le,
	1000, 1, 0,
	48000, 48000, 48000)

# Low Latency capture pipeline 2 on PCM 0 using max 2 channels of s32le.
# 1000us deadline on core 0 with priority 0
PIPELINE_PCM_ADD(sof/pipe-low-latency-capture.m4,
	2, 0, 2, s32le,
	1000, 0, 0,
	48000, 48000, 48000)

#
# DAI configuration
#
# SSP port 2 is our only pipeline DAI
#

# playback DAI is SSP2 using 2 periods
# Buffers use s16le format, 1000us deadline on core 0 with priority 1
DAI_ADD(sof/pipe-dai-playback.m4,
	1, SSP, 2, SSP2-Codec,
	PIPELINE_SOURCE_1, 2, s16le,
	1000, 1, 0, SCHEDULE_TIME_DOMAIN_DMA)

# PCM Media Playback pipeline 3 on PCM 1 using max 2 channels of s32le.
# 4000us deadline on core 0 with priority 0
PIPELINE_PCM_ADD(sof/pipe-pcm-media.m4,
	3, 1, 2, s32le,
	4000, 0, 0,
	8000, 48000, 48000,
	0, PIPELINE_PLAYBACK_SCHED_COMP_1)

# Connect pipelines together
SectionGraph."pipe-cht-max98090" {
	index "0"

	lines [
		# media 0
		dapm(PIPELINE_MIXER_1, PIPELINE_SOURCE_3)
	]
}

# capture DAI is SSP2 using 2 periods
# Buffers use s16le format, 1000us deadline on core 0 with priority 0
DAI_ADD(sof/pipe-dai-capture.m4,
	2, SSP, 2, SSP2-Codec,
	PIPELINE_SINK_2, 2, s16le,
	1000, 0, 0, SCHEDULE_TIME_DOMAIN_DMA)

# PCM Low Latency
PCM_DUPLEX_ADD(Low Latency, 0, PIPELINE_PCM_1, PIPELINE_PCM_2)

#
# BE configurations - overrides config in ACPI if present
#
DAI_CONFIG(SSP, 2, 0, SSP2-Codec,
	   SSP_CONFIG(I2S, SSP_CLOCK(mclk, 19200000, codec_mclk_in),
		      SSP_CLOCK(bclk, 1920000, codec_slave),
		      SSP_CLOCK(fsync, 48000, codec_slave),
		      SSP_TDM(2, 20, 3, 3),
		      SSP_CONFIG_DATA(SSP, 2, 16)))

VIRTUAL_WIDGET(ssp2 Rx, out_drv, 1)
VIRTUAL_WIDGET(ssp2 Tx, out_drv, 2)
