function [types, names, short_names] = getLiblinearTypes()
% GETLIBLINEARTYPES Get all liblinear types and names

types = [0:7, 11:13];

names = {...
    'L2-regularized logistic regression (primal)', ...
    'L2-regularized L2-loss support vector classification (dual)', ...
    'L2-regularized L2-loss support vector classification (primal)', ...
    'L2-regularized L1-loss support vector classification (dual)', ...
    'support vector classification by Crammer and Singer', ...
    'L1-regularized L2-loss support vector classification', ...
    'L1-regularized logistic regression', ...
    'L2-regularized logistic regression (dual)', ...
    'L2-regularized L2-loss support vector regression (primal)', ...
    'L2-regularized L2-loss support vector regression (dual)', ...
    'L2-regularized L1-loss support vector regression (dual)'};

short_names = {...
    'l2rp_lr', 'l2rl2ld_svc', 'l2rl2lp_svc', 'l2rl1ld_svc', ...
    'cs_svc', 'l1rl2l_svc', 'l1r_lr', 'l2rd_lr', 'l2rl2lp_svr', ...
    'l2rl2ld_svr', 'l2rl1ld_svr'};

end
