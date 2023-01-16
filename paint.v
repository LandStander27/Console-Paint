module main

import term.ui as tui
import term

import time

struct TerminalSize {
	x int
	y int
}

struct Point {
mut:
	x int
	y int
}

const (

	yellow = tui.Color{255,255,0}
	green = tui.Color{0,255,0}
	red = tui.Color{255,0,0}
	blue = tui.Color{0,0,255}
	white = tui.Color{255,255,255}
	black = tui.Color{0,0,0}

	res = get_initial_size()

	

)

fn get_initial_size() TerminalSize {
	w, h := term.get_terminal_size()
	return TerminalSize{w, h}
}

[heap]
struct App {

	mut:

		tui &tui.Context = unsafe { 0 }
		pos Point = Point{0,0}
		mouse_down bool

		board [][]tui.Color

		last_update time.StopWatch = time.new_stopwatch()
		last_selection_time time.StopWatch = time.new_stopwatch()

		selected tui.Color = white

		green Point = Point{3,res.y-7}
		yellow Point = Point{6, res.y-7}

		white Point = Point{3,res.y-4}

		selection_pos Point = Point{3,res.y-4}

}

fn (mut a App) draw(point Point, c tui.Color) {

	a.tui.set_bg_color(c)
	a.tui.draw_line(point.x, point.y, point.x, point.y)

}

fn (mut app App) frame() {
	for x in 0..res.x {
		for y in 0..res.y {
			app.draw(Point{x,y}, app.board[x][y])
		}
	}

	app.tui.set_cursor_position(0, 0)
	app.tui.write(app.pos.str())

	if app.last_update.elapsed().milliseconds() > 25 {
		app.tui.reset()
		app.tui.flush()
		app.last_update.restart()
	}


}

fn (mut app App) event(e &tui.Event, x voidptr) {


	match e.typ {
		.key_down {
			match e.code {
				.escape {
					term.show_cursor()
					exit(0)
				}
				else {}
			}
		}
		.mouse_move {
			app.pos = Point{e.x,e.y}
			
		}
		.mouse_down {
			if e.button == .left {
				if app.last_selection_time.elapsed().milliseconds() > 100 && app.pos != app.selection_pos {
					
					if app.pos == app.green {
						app.make_selection(app.green)
						app.selected = green
						app.deselect(app.selection_pos)
						app.selection_pos = app.green
					} else if app.pos == app.yellow {
						app.make_selection(app.yellow)
						app.selected = yellow
						app.deselect(app.selection_pos)
						app.selection_pos = app.yellow
					}
					app.last_selection_time.restart()
				}

				app.mouse_down = true
			}
			if e.button == .right {
				app.mouse_down = false
			}
			
		}
		else {}
	}

}

fn (mut app App) watch_mouse() {
	for {
		if app.mouse_down && (app.pos.x < res.x && app.pos.x > 0 && app.pos.y < res.y && app.pos.y > 0) && app.pos.y < res.y - 10 {
			app.board[app.pos.x][app.pos.y] = app.selected 
		}
		if app.pos.y > res.y - 10 {
			app.mouse_down = false
		}
	}
}

fn (mut app App) make_selection(point Point) {
	app.board[point.x-1][point.y+1] = white
	app.board[point.x][point.y+1] = white
	app.board[point.x+1][point.y+1] = white

	app.board[point.x-1][point.y] = white
	app.board[point.x-1][point.y-1] = white

	app.board[point.x][point.y-1] = white
	app.board[point.x+1][point.y-1] = white

	app.board[point.x+1][point.y] = white

}

fn (mut app App) deselect(point Point) {
	app.board[point.x-1][point.y+1] = black
	app.board[point.x][point.y+1] = black
	app.board[point.x+1][point.y+1] = black

	app.board[point.x-1][point.y] = black
	app.board[point.x-1][point.y-1] = black

	app.board[point.x][point.y-1] = black
	app.board[point.x+1][point.y-1] = black

	app.board[point.x+1][point.y] = black
}

fn (mut app App) make_ribbon() {
	app.board[3][res.y-7] = green
	app.board[6][res.y-7] = yellow
	app.board[3][res.y-4] = white
}

fn main() {

	mut app := &App{}

	for _ in 0..res.x {
		mut row := []tui.Color{}
		for _ in 0..res.y {
			row << black
		}
		app.board << row
	}

	for x in 0..res.x {
		app.board[x][app.board[x].len-10] = white
	}

	app.make_ribbon()
	app.make_selection(app.white)

	app.tui = tui.init(
		user_data: app
		hide_cursor: true
		capture_events: true
		frame_fn: app.frame
		event_fn: app.event
		frame_rate: 60
		
	)

	mut threads := []thread{}

	threads << spawn app.watch_mouse()

	app.tui.run() or { println(err) }

	threads.wait()

}
