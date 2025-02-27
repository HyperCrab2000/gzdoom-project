if(NOT TARGET gzdoom_pk3)
    add_custom_target(gzdoom_pk3)
endif()

add_pk3(gzdoom.pk3 ${CMAKE_CURRENT_SOURCE_DIR}/static)
