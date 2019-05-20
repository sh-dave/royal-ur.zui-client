let prj = new Project('ruz');

prj.addParameter('-dce full');
prj.addDefine('analyzer_optimize');

prj.localLibraryPath = 'libs';

await prj.addProject('libs/royal-ur.logic')
	prj.addLibrary('coconut.data');
prj.addLibrary('zui');

prj.addSources('src');
prj.addAssets('assets/**');
prj.addAssets(`assets-${platform}`);

resolve(prj);
