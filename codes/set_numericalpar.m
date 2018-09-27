function [numericalpar] = set_numericalpar()
    
    qmin = 0.001; %maybe set to 0, need to see if it works or fucks things up
    qmax = 4; % this is relative. this is saying i keep track of the distribution up to 4x  the average quality. may need to change.
    qnumpoints = 100;
    numericalpar.qgrid = linspace(qmin,qmax,qnumpoints);
    
    mmin = 0;
    mmax = 5;
    mnumpoints = 100;
    numericalpar.mgrid = linspace(mmin,mmax,mnumpoints);
   
end

    
    
    
    
    
    
    