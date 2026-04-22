extends SceneTree
func _init():
    var v = Engine.get_version_info()
    print("MAJOR: ", v.major)
    print("MINOR: ", v.minor)
    print("PATCH: ", v.patch)
    print("STATUS: ", v.status)
    print("BUILD: ", v.build)
    print("STRING: ", v.string)
    quit()
