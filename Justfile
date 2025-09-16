wally:
	wally install
	rojo sourcemap tests.project.json > sourcemap.json
	wally-package-types --sourcemap sourcemap.json Packages
	wally-package-types --sourcemap sourcemap.json DevPackages

luau:
	rojo sourcemap ./tests.project.json > sourcemap.json
	luau-lsp analyze --defs=globalTypes.d.luau --sourcemap=sourcemap.json --no-strict-dm-types --ignore=**/src/shared/Data/MockVideosStudio/** --ignore=**/Packages/** --ignore=**/ServerPackages/** --flag:LuauInstantiateInSubtyping=True --flag:LuauFixIndexerSubtypingOrdering=True --flag:LuauSolverV2=False ./src ./stories
