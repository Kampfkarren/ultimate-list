wally:
	wally install
	rojo sourcemap tests.project.json > sourcemap.json
	wally-package-types --sourcemap sourcemap.json Packages
	wally-package-types --sourcemap sourcemap.json DevPackages
