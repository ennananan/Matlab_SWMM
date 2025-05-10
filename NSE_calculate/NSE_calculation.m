function [E]=NSE_calculation(A,B)
%计算单个变量下的序列NSE

[n_A,m_A]=size(A);
[n_B,m_B]=size(B);
if (n_A==n_B)&&(m_A==m_B)
    E=zeros(m_A,1);
    for i=1:m_A
        C=A(:,i)-B(:,i);
        m=dot(C,C);
        mean_A=mean(A(:,i));
        A_difference=A(:,i)-mean_A;
        n=dot(A_difference,A_difference);
        E(i)=1-m/n;
    end
else
    E="error! A&B have different size";
end
end