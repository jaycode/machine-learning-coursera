clear all;
clc;
addpath('mksqlite');
mksqlite('open','forex_predictor.db');
mksqlite('DROP TABLE x_daily');
mksqlite('DROP TABLE y_daily');