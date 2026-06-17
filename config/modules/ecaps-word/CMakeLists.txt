if(CONFIG_ZMK_BEHAVIOR_ECAPS_WORD)
  zephyr_library()
  zephyr_library_sources(src/behavior_ecaps_word.c)
  # drivers/behavior.h lives in the ZMK application's private include tree;
  # add it explicitly so the external module can see it.
  zephyr_library_include_directories(${CMAKE_SOURCE_DIR}/include)
endif()
