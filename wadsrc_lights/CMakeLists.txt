if(NOT TARGET lights_pk3)
    add_custom_target(lights_pk3)
endif()


add_pk3(lights.pk3 ${CMAKE_CURRENT_SOURCE_DIR}/static)
