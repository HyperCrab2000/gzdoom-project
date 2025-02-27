if(NOT TARGET brightmaps_pk3)
    add_custom_target(brightmaps_pk3)
endif()

add_pk3(brightmaps.pk3 ${CMAKE_CURRENT_SOURCE_DIR}/static)
