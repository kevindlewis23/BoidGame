class_name UndoRedoThing

var state_list = []
var cur_index = -1

func add_state(state):
	if cur_index < state_list.size() - 1:
		state_list = state_list.slice(0, cur_index + 1)
	cur_index += 1
	state_list.append(state)

func undo():
	if cur_index > 0:
		cur_index -= 1
		return state_list[cur_index]
	return null

func redo():
	if cur_index < state_list.size() - 1:
		cur_index += 1
		return state_list[cur_index]
	return null