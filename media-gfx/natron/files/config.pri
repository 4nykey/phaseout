boost: LIBS += -lboost_serialization
python: LIBS += -l@EPYTHON@
CONFIG(notests): SUBDIRS -= Tests
