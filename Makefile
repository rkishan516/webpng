SHELL := /bin/bash

.EXPORT_ALL_VARIABLES:
SRC_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
LIB_DIR := $(SRC_DIR)/lib

.PHONY: proto-gen
proto-gen:
	rinf message
