if(NOT TARGET game_widescreen_gfx_pk3)
    add_custom_target(game_widescreen_gfx_pk3)
endif()

add_pk3(game_widescreen_gfx.pk3 ${CMAKE_CURRENT_SOURCE_DIR}/static)
