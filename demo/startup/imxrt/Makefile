.PHONY: sdp-boot flash-boot flash-app ram-boot

sdp-boot:
	$(QUITE) $(MAKE) -C sdp-boot PLATFORM=IMXRT version postlink

flash-boot:
	$(QUITE) $(MAKE) -C flash-boot PLATFORM=IMXRT version postlink

flash-app:
	$(QUITE) $(MAKE) -C flash-app PLATFORM=IMXRT version postlink

ram-boot:
	$(QUITE) $(MAKE) -C ram-boot PLATFORM=IMXRT version postlink


clean:
	$(QUITE) $(MAKE) -C sdp-boot PLATFORM=IMXRT clean
