function result = toRRArray(allRR)
%result = toRRArray(allRR) - convert a struct with per-subject results to
%an array

    result = myarrayfun(@(s)allRR.(s{1}), tt.reg.listInitials(allRR));

end

