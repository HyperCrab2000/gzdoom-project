if(NOT TARGET game_support_pk3)
    add_custom_target(game_support_pk3)
endif()


add_pk3(game_support.pk3 ${CMAKE_CURRENT_SOURCE_DIR}/static)
