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
	erase = tui.Color{0,0,0}

	gray = tui.Color{200,200,200}

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

		cleared_time time.StopWatch = time.new_stopwatch()

		selected tui.Color = white

		green Point = Point{3,res.y-2}
		yellow Point = Point{6, res.y-2}

		white Point = Point{9,res.y-2}
		red Point = Point{12, res.y-2}
		blue Point = Point{15, res.y-2}

		selection_pos Point = Point{9,res.y-2}

		erase []Point = [Point{res.x-20,res.y-2}, Point{res.x-14,res.y-2}]
		clear []Point = [Point{res.x-10,res.y-2}, Point{res.x-5,res.y-2}]

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

	app.tui.set_cursor_position(app.erase[0].x, app.erase[0].y)
	app.tui.write(if app.selected == erase { term.bg_white(term.black("Eraser")) } else {"Eraser"})

	app.tui.set_cursor_position(app.clear[0].x, app.clear[0].y)
	app.tui.write(if app.cleared_time.elapsed().milliseconds() < 50 { term.bg_white(term.black("Clear")) } else {"Clear"})

	// app.tui.set_cursor_position(0, 0)
	// app.tui.write(app.pos.str())

	if app.last_update.elapsed().milliseconds() > 25 {
		app.tui.reset()
		app.tui.flush()
		app.last_update.restart()
	}


}

fn (mut app App) event(e &tui.Event, w voidptr) {


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
				if app.pos != app.selection_pos {
					
					match app.pos {
						app.green {
							app.make_selection(app.green)
							app.selected = green
							app.deselect(app.selection_pos)
							app.selection_pos = app.green
						}
						app.yellow {
							app.make_selection(app.yellow)
							app.selected = yellow
							app.deselect(app.selection_pos)
							app.selection_pos = app.yellow
						}
						app.white {
							app.make_selection(app.white)
							app.selected = white
							app.deselect(app.selection_pos)
							app.selection_pos = app.white
						}
						app.red {
							app.make_selection(app.red)
							app.selected = red
							app.deselect(app.selection_pos)
							app.selection_pos = app.red
						}
						app.blue {
							app.make_selection(app.blue)
							app.selected = blue
							app.deselect(app.selection_pos)
							app.selection_pos = app.blue
						}
						else {}
					}
					if app.pos.x > app.erase[0].x && app.pos.x < app.erase[1].x && app.pos.y == app.erase[0].y {
						app.deselect(app.selection_pos)
						app.selected = erase
						app.selection_pos = app.erase[0]
					}
					if app.pos.x > app.clear[0].x && app.pos.x < app.clear[1].x && app.pos.y == app.clear[0].y {
						for x in 0..app.board.len {
							for y in 0..app.board.len {
								if y < res.y-5 {
									app.board[x][y] = erase
								}
							}

						}
						app.cleared_time.restart()
					}
				}
				if app.pos.y > res.y-5 {
					return
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
		p := app.pos
		if app.mouse_down && (p.x < res.x && p.x > 0 && p.y < res.y && p.y > 0) && p.y < res.y - 5 {
			app.board[p.x][p.y] = app.selected 
		}
	}
}

fn (mut app App) make_selection(point Point) {
	app.board[point.x-1][point.y+1] = gray
	app.board[point.x][point.y+1] = gray
	app.board[point.x+1][point.y+1] = gray

	app.board[point.x-1][point.y] = gray
	app.board[point.x-1][point.y-1] = gray

	app.board[point.x][point.y-1] = gray
	app.board[point.x+1][point.y-1] = gray

	app.board[point.x+1][point.y] = gray

}

fn (mut app App) deselect(point Point) {
	app.board[point.x-1][point.y+1] = erase
	app.board[point.x][point.y+1] = erase
	app.board[point.x+1][point.y+1] = erase

	app.board[point.x-1][point.y] = erase
	app.board[point.x-1][point.y-1] = erase

	app.board[point.x][point.y-1] = erase
	app.board[point.x+1][point.y-1] = erase

	app.board[point.x+1][point.y] = erase
}

fn (mut app App) make_ribbon() {
	app.board[3][res.y-2] = green
	app.board[6][res.y-2] = yellow
	app.board[9][res.y-2] = white
	app.board[12][res.y-2] = red
	app.board[15][res.y-2] = blue
}

fn main() {

	mut app := &App{}

	for _ in 0..res.x {
		mut row := []tui.Color{}
		for _ in 0..res.y {
			row << erase
		}
		app.board << row
	}

	for x in 0..res.x {
		app.board[x][app.board[x].len-5] = white
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
