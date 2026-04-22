@tool
extends EditorScript
func _run():
    var classes = ClassDB.get_class_list()
    for c in classes:
        if c.contains("Android") or c.contains("Export"):
            print(c)
