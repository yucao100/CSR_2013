    
function master_train(vid_file_string, path, keyphrase, dim3D)  
%vid_file_string is the directory containing the training videos
%path is the path to the release directory containing this code
%keyphrase indicates the beginning phrase of the training videos, e.g. 
%"actioncliptrain"
%dim3D indicates whether the videos are 3D videos with depth data, e.g.
%from Kinect, or 2D, e.g. videoname.avi

%% set paths

addpath(path);
addpath([path, '/activation_functions/']);
addpath([path, '/mmread/']);
addpath([path, '/tbox/']);

bases_path = [path, '/bases/']; %store trained filters/bases

unsup_train_data_path = [path, '/unsup_data/']; %a few Gb

%% parameters
load_layers = 0; % option to load pre-trained bases in the network
num_unsup_samples_per_clip = [200; 200; 200];	%3x1 column vector

%% set up network parameters
% (2 layer network set up, see set_network_params.m)
if dim3D
    network_params = set_network_params_3D();
else
    network_params = set_network_params();
end

%% build multi-isa network
network = build_network(network_params, load_layers, bases_path);                                                                              

%% name/locate unsupervised training data
for i = 1:network.num_isa_layers
    data_file_name{i} = sprintf('blktrain_%dx%dx%d_np%d.mat', network.isa{i}.fovea.spatial_size,network.isa{i}.fovea.spatial_size, network.isa{i}.fovea.temporal_size, num_unsup_samples_per_clip(i));
    data_path_file_name{i} = [unsup_train_data_path, data_file_name{i}];
    fprintf('accessing data at: %s\n', data_path_file_name{i});
end

%% extract unsup training data
for i = 1:network.num_isa_layers %1 and 2 layers (since 3rd layer is the same size)       
    params_ex.spatial_size = network.isa{i}.fovea.spatial_size;
    params_ex.temporal_size = network.isa{i}.fovea.temporal_size;
    params_ex.num_patches = num_unsup_samples_per_clip(i);         %i is either 1 or 2. number of patches is always 200  
    
    %% execute extract data (we do with separate computers)    
    extract_unsupervised_training_data_hw2(vid_file_string, data_path_file_name{i}, params_ex, keyphrase, dim3D); 
    disp('iteration done')
end

%% execute train l1
    train_isa(network, data_path_file_name{1}, bases_path, set_training_params(1, network_params)); %

%% execute train l2
network = build_network(network_params, 1, bases_path);
train_isa(network, data_path_file_name{2}, bases_path, set_training_params(2, network_params));
