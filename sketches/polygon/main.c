/************************************************************/ /**
*
*	@file: main.cpp
*	@author: Martin Fouilleul
*	@date: 30/07/2022
*	@revision:
*
*****************************************************************/
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define _USE_MATH_DEFINES //NOTE: necessary for MSVC
#include <math.h>

#include "milepost.h"

int main()
{
    mp_init();
    mp_clock_init(); //TODO put that in mp_init()?

    mp_rect windowRect = { .x = 100, .y = 100, .w = 810, .h = 610 };
    mp_window window = mp_window_create(windowRect, "test", 0);

    mp_rect contentRect = mp_window_get_content_rect(window);

    //NOTE: create surface
    mg_surface surface = mg_surface_create_for_window(window, MG_CANVAS);
    mg_surface_swap_interval(surface, 1);

    if(mg_surface_is_nil(surface))
    {
        printf("Error: couldn't create surface\n");
        return (-1);
    }

    //TODO: create canvas
    mg_canvas canvas = mg_canvas_create();

    if(mg_canvas_is_nil(canvas))
    {
        printf("Error: couldn't create canvas\n");
        return (-1);
    }

    // start app
    mp_window_bring_to_front(window);
    mp_window_focus(window);

    f64 frameTime = 0;
    f32 x = 0, y = 0;

    while(!mp_should_quit())
    {
        f64 startTime = mp_get_time(MP_CLOCK_MONOTONIC);

        mp_pump_events(0);
        mp_event* event = 0;
        while((event = mp_next_event(mem_scratch())) != 0)
        {
            switch(event->type)
            {
                case MP_EVENT_WINDOW_CLOSE:
                {
                    mp_request_quit();
                }
                break;

                case MP_EVENT_KEYBOARD_KEY:
                {
                    if(event->key.action == MP_KEY_PRESS)
                    {
                        if(event->key.code == MP_KEY_LEFT)
                        {
                            x -= 1;
                        }
                        if(event->key.code == MP_KEY_RIGHT)
                        {
                            x += 1;
                        }
                        if(event->key.code == MP_KEY_UP)
                        {
                            y -= 1;
                        }
                        if(event->key.code == MP_KEY_DOWN)
                        {
                            y += 1;
                        }
                    }
                }
                break;

                default:
                    break;
            }
        }

        mg_surface_prepare(surface);

        // background
        mg_set_color_rgba(0, 1, 1, 1);
        mg_clear();

        mg_move_to(100, 100);
        mg_line_to(150, 150);
        mg_line_to(100, 200);
        mg_line_to(50, 150);
        mg_close_path();
        mg_set_color_rgba(1, 0, 0, 1);
        mg_fill();

        mg_move_to(200, 100);
        mg_line_to(410, 100);
        mg_line_to(410, 200);
        mg_line_to(200, 200);
        mg_close_path();
        mg_set_color_rgba(0, 1, 0, 1);
        mg_fill();

        mg_set_color_rgba(0, 1, 1, 0.5);
        mg_rectangle_fill(120, 120, 200, 200);

        mg_set_color_rgba(1, 0, 0.5, 1);
        mg_rectangle_fill(700, 500, 200, 200);

        mg_move_to(300, 300);
        mg_quadratic_to(400, 500, 500, 300);
        mg_close_path();
        mg_set_color_rgba(0, 0, 1, 1);
        mg_fill();

        mg_move_to(200, 450);
        mg_cubic_to(200, 250, 400, 550, 400, 450);
        mg_close_path();
        mg_set_color_rgba(1, 0.5, 0, 1);
        mg_fill();

        /*
			mg_set_joint(MG_JOINT_NONE);
			mg_set_max_joint_excursion(20);

			mg_set_cap(MG_CAP_SQUARE);

			mg_move_to(x+200, y+200);
			mg_line_to(x+300, y+300);
			mg_line_to(x+200, y+400);
			mg_line_to(x+100, y+300);
			mg_close_path();
			mg_set_color_rgba(1, 0, 0, 1);
		//	mg_set_width(2);
			mg_stroke();

			mg_move_to(400, 400);
			mg_quadratic_to(600, 601, 800, 400);
			mg_set_color_rgba(0, 0, 1, 1);
			mg_stroke();

			mg_move_to(x+400, y+300);
			mg_cubic_to(x+400, y+100, x+600, y+400, x+600, y+300);
			mg_close_path();
			mg_set_color_rgba(0, 0, 1, 1);
			mg_stroke();

			mg_set_color_rgba(1, 0, 0, 1);
			mg_rounded_rectangle_fill(100, 100, 200, 300, 20);

			mg_move_to(x+8, y+8);
			mg_line_to(x+33, y+8);
			mg_line_to(x+33, y+19);
			mg_line_to(x+8, y+19);
			mg_close_path();
			mg_set_color_rgba(0, 0, 1, 1);
			mg_fill();
*/
        printf("Milepost vector graphics test program (frame time = %fs, fps = %f)...\n",
               frameTime,
               1. / frameTime);

        mg_render(surface, canvas);
        mg_surface_present(surface);

        mem_arena_clear(mem_scratch());
        frameTime = mp_get_time(MP_CLOCK_MONOTONIC) - startTime;
    }

    mg_canvas_destroy(canvas);
    mg_surface_destroy(surface);
    mp_window_destroy(window);

    mp_terminate();

    return (0);
}