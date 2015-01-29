setwd('/Users/Macbook/Desktop/Machine Learning and Data Analysis/Data Analysis Projects/QI Appearances')
df = read.csv('QI_data.csv', as.is=T)

# Break up episode information, eliminate winner information
episode_df = data.frame(do.call(rbind, strsplit(df$Episode,' ')), stringsAsFactors=F)
colnames(episode_df) = c("Episode.Season","Episode.All")
episode_df$Episode.All = sapply(episode_df$Episode.All, function(x) substr(x,2,nchar(x)-1))
df = cbind(df[,-c(2,5)],episode_df)

sort(table(df$Episode.All), decreasing=T)
# Note that episode 75 includes 4 guests, not 3; remove it to make the math easier
df = df[df$Episode.All != 75,]

# Fix contestant names as needed
table(df$Guests)
df$Guests[df$Guests == "Dara \xd3 Briain"] = "Dara O'Briain"
df$Guests[df$Guests == "Victoria Coren"] = "Victoria Coren Mitchell"

# Fix Episode names
table(df$Title)
df$Title[df$Title == "\"Death\"(Hallowe'en\xa0Special)"] = "\"Death\"(Hallowe'en Special)"
df$Title[df$Title == "\"Descendants\"(Children in Need\xa0Special)"] = "\"Descendants\"(Children in Need Special)"

# Add multiple guest columns to encode co-guests for igraph
# We don't have to change the number of rows because 3 = (3 choose 2)
get_guest_pairs = function(guest_names){
  matrix(c(guest_names[1],guest_names[2], guest_names[2],guest_names[3],
           guest_names[3],guest_names[1]), nrow=3, ncol=2, byrow=T)
}
df$Guest1 = NA
df$Guest2 = NA
for (i in 1:(nrow(df)/3)){
  start_ind = i*3 - 2
  end_ind = i*3
  df[start_ind:end_ind,7:8] = get_guest_pairs(df$Guests[start_ind:end_ind])
}

# Save guest appearance counts for later (to be used for vertex size)
guest_df = as.data.frame(table(df$Guests))
names(guest_df) = c("Guest","Freq")
setwd('/Users/Macbook/Desktop/Machine Learning and Data Analysis/Data Analysis Projects/QI Appearances')
write.csv(guest_df,'guest_freqs.csv', row.names=F)

# Count the number of times each pair appears:
df$Cooccurrence_Count = NA
for (i in 1:nrow(df)){
  df$Cooccurrence_Count[i] = sum((df$Guest1==df$Guest1[i] & df$Guest2==df$Guest2[i]) | (df$Guest1==df$Guest2[i] & df$Guest2==df$Guest1[i]))
}

# Original formula:
# (n_e n_c) * 6^n_c * ((n_e-n_c) (g1+g2-2n_c)) * ((g1+g2-2n_c) (g1-n_c)) * 3^(g1+g2-2n_c)
# Simplified formula:
# 2^n_c * 3^(g1+g2-n_c) * (n_e n_c) * ((n_e-n_c) (g1-n_c)) * ((n_e-g_1) (g2-n_c))
# In both cases, the total count is the above formula summed from 0 to min(g_1,g_2)
single_term_formula = function(g1, g2, n_c, n_e){
  return (2^n_c * 3^(g1+g2-n_c) * choose(n_e, n_c) * choose(n_e-n_c, g1-n_c) * choose(n_e-g1, g2-n_c))
}
get_cooccurance_prob = function(guest_count1, guest_count2, num_cooccurances, num_episodes=168, type='exact'){ #168 episodes total
  if (type=='exact'){
    numerator = single_term_formula(guest_count1, guest_count2, num_cooccurances, num_episodes)
  } else if (type=='leq'){
    numerator = 0
    for (this_cooccurance in 0:num_cooccurances){
      numerator = numerator + single_term_formula(guest_count1, guest_count2, this_cooccurance, num_episodes)
    }
  } else if (type=='geq'){
    numerator = 0
    for (this_cooccurance in num_cooccurances:min(guest_count1,guest_count2)){
      numerator = numerator + single_term_formula(guest_count1, guest_count2, this_cooccurance, num_episodes)
    }
  }
  denom = 0
  for (this_cooccurance in 0:min(guest_count1,guest_count2)){
    denom = denom + single_term_formula(guest_count1, guest_count2, this_cooccurance, num_episodes)
  }  
  return (numerator/denom)
}


# Compute the probability of each co-occurance count:
df$Cooccurrence_Prob.exact = NA
df$Cooccurrence_Prob.leq = NA
df$Cooccurrence_Prob.geq = NA
df$Cooccurrence_Prob.extreme = NA
df$Cooccurrence_Prob.extreme.type = NA
for (i in 1:nrow(df)){
  guest_count1 = guest_df$Freq[guest_df$Guest == df$Guest1[i]]
  guest_count2 = guest_df$Freq[guest_df$Guest == df$Guest2[i]]
  num_cooccurances = df$Cooccurrence_Count[i]
  df$Cooccurrence_Prob.exact[i] = get_cooccurance_prob(guest_count1,guest_count2,num_cooccurances)
  df$Cooccurrence_Prob.leq[i] = get_cooccurance_prob(guest_count1,guest_count2,num_cooccurances,type='leq')
  df$Cooccurrence_Prob.geq[i] = get_cooccurance_prob(guest_count1,guest_count2,num_cooccurances,type='geq')
  if (df$Cooccurrence_Prob.leq[i] < df$Cooccurrence_Prob.geq[i]){
    df$Cooccurrence_Prob.extreme[i] = df$Cooccurrence_Prob.leq[i]
    df$Cooccurrence_Prob.extreme.type[i] = 'less'
  } else if (df$Cooccurrence_Prob.leq[i] > df$Cooccurrence_Prob.geq[i]){
    df$Cooccurrence_Prob.extreme[i] = df$Cooccurrence_Prob.geq[i]
    df$Cooccurrence_Prob.extreme.type[i] = 'greater'
  } else{
    df$Cooccurrence_Prob.extreme[i] = df$Cooccurrence_Prob.leq[i]
    df$Cooccurrence_Prob.extreme.type[i] = 'both'
  }
}

# Reorder/rename the columns, and save
df = df[,c(2,1,5,6,4,3,7:14)]
names(df)[1:6] = c("Title","Season_Num","Episode_Num.Season","Episode_Num.All","Airdate","Guest")
setwd('/Users/Macbook/Desktop/Machine Learning and Data Analysis/Data Analysis Projects/QI Appearances')
write.csv(df,'QI_data_CLEAN.csv', row.names=F)
