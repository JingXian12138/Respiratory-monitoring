# Respiratory-monitoring
基于超像素(super-pixel)边缘检测的呼吸监测

## 对比实验
本文算法和基于小波去噪的方法、基于EVM的方法以及基于PVM的方法进行对比实验
基于小波去噪的方法根据论文"张言飞, 欧阳健飞, and 姚丽峰. "基于快速人脸检测的实时呼吸测量系统的设计." 计算机工程与应用 v.52;No.849.02(2016):260-265."复现
EVM和PVM的原理参见：
EVM：http://people.csail.mit.edu/mrub/evm/
PVM：http://people.csail.mit.edu/nwadhwa/phase-video/

## 结果展示
在原视频中提取呼吸信号，将信号插入PVM增强后的视频中，进行一致性检验
result video文件夹中为三种呼吸状态下的呼吸信号提取结果
original video文件夹为原始视频

## 代码运行
data：n_test*.mp4为近距离状态下(2m)拍摄的视频；f_test*.mp4为远距离状态下(4.5m)拍摄的视频；拍摄test01.mp4时呼吸区位移，检测动态调整机制的有效性
修改文件开始的dataName即可测试不同状态下算法的呼吸检测曲线
正常呼吸：f_test12，n_test15
屏住呼吸：f_test13，n_test16
呼吸暂停：f_test14，n_test17
注：f_test13呼吸区定位模块有误判，将注释%呼吸区定位下方的index选择部分由max改为min即可

./wavelet_rr_estimation.m 小波去噪
./sp_RR 本文算法 superpixel_rr.m 无动态调整机制 superpixel_rr_adapt.m 含动态调整机制
./EVM_based 基于EVM的算法 rr_monitoring.m 运行前需根据EVM源代码的提示进行预处理（编译相关模块等）
./PVM_based 基于PVM的算法 rr_monitoring.m 运行前需根据PVM源代码的提示进行预处理（编译相关模块等）
基于EVM和基于PVM的算法根据EVM和PVM源码提取出相关变量求解得到
