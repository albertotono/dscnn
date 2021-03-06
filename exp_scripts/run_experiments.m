% function run_experiments()

setup;
expDir = 'data';

%% modelnet experiments (w/ upright assumption)
get_imdb('ModelNet40_off', ...
  'func', @(s) setup_imdb_modelnet(s,'useUprightAssumption',true), ...
  'rebuild', true);



% fast approximation training
% forward pass; compute CNN relu7 features; use vgg-m downloaded from matconvnet server
expDir = 'data';
load('data/ModelNet40_off/imdb.mat');
addpath(genpath(imageDir));
system('rm -r data/features');
feats = cnn_shape_get_features( images.name, 'imagenet-matconvnet-vgg-m', ...
    {'relu7'} , 'batchSize' , 720 , 'nViews', 1);
save('feats/fastapprox_relu7.mat', '-v7.3');

% SVM script; save cluster hierachy
SVM_v_fast_approx;



% DS CNN; 12 views; rgb; 
load('clusterAssigned.mat');
cnn_shape('ModelNet40_off', ...
  'expDir', fullfile(expDir,'rgb/modelnet40_DS_relu6'), ...
  'numFetchThreads', 12, ...
  'pad', 32, ...
  'border', 32, ...
  'baseModel', fullfile('imagenet-matconvnet-vgg-m'), ...
  'multiview', true, ...
  'cluster_pool',true,...
  'clusterpoolType',{'max','avg','max'},...
  'cluster',clusterAssigned,...
  'viewpoolPos', 'relu6', ...
  'batchSize', 40, ...
  'gpus', [1], ...
  'includeVal', true, ...
  'maxIterPerEpoch', Inf, ...
  'numEpochs', [0 30 0], ...
  'learningRate', [0.005*ones(1,5) 0.001*ones(1,5) 0.0001*ones(1,10) 0.00001*ones(1,10)] ...
);  

% compute features
load('data/ModelNet40_off/imdb.mat');
addpath(genpath(imageDir));
system('rm -r data/features');
feats = cnn_shape_get_features( images.name, '../rgb/modelnet40_DS_relu6/net-deployed', ...
    {'relu7'} , 'batchSize' , 60 , 'nViews', 12);
save('feats/DS_relu6_endtoend.mat', '-v7.3');

% get classification accuracy
SVM_v_end_to_end



