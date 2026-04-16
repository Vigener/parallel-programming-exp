CXX = mpic++
CXXFLAGS ?= -O3 -Wall
LDFLAGS ?=

SOURCES := $(wildcard *.cpp)
TARGETS := $(SOURCES:.cpp=)

.PHONY: all clean list

all: $(TARGETS)

# Build each executable from the matching .cpp source file.
%: %.cpp
	$(CXX) $(CXXFLAGS) $< -o $@ $(LDFLAGS)

list:
	@printf "%s\n" $(TARGETS)

clean:
	rm -f $(TARGETS)
