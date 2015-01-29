library(igraph)

setwd('/Users/Macbook/Desktop/Machine Learning and Data Analysis/Data Analysis Projects/QI Appearances')
df = read.csv('QI_data_CLEAN.csv', as.is=T)
guest_df = read.csv('guest_freqs.csv', as.is=T)

table(guest_df$Freq)
# We're only interested in those guests who were on the show at least 5 times:
rows_to_keep = c()
for (i in 1:nrow(df)){
  if (guest_df$Freq[guest_df$Guest==df$Guest1[i]]>4 && guest_df$Freq[guest_df$Guest==df$Guest2[i]]>4){
    rows_to_keep = c(rows_to_keep, i)
  }
}
df_sub = df[rows_to_keep,] # reduced from 120 guests down to just 22

# Remove multi-edges (replace with edges of varying width)
unique_pairs = unique(df_sub[,c("Guest1","Guest2")])
rows_to_remove = c()
for (i in 1:nrow(unique_pairs)){
  for (j in i:nrow(unique_pairs)){
    if (unique_pairs[i,1]==unique_pairs[j,2] && unique_pairs[i,2]==unique_pairs[j,1]){
      rows_to_remove = c(rows_to_remove,j)
    }
  }
}
unique_pairs = unique_pairs[-rows_to_remove,]
rows_to_keep = c()
for (i in 1:nrow(unique_pairs)){
  this_ind = which(df_sub$Guest1==unique_pairs[i,1] & df_sub$Guest2==unique_pairs[i,2])[1]
  rows_to_keep = c(rows_to_keep, this_ind)
}
df_sub = df_sub[rows_to_keep,]

# Initialize the graph object
gdf = graph.data.frame(df_sub[,c(7:8,1:5,9:14)], directed=F)
length(V(gdf)) # 22 guests
length(E(gdf)) # 126 pairs

# Size vertices by number of appearances
V(gdf)$size = 3*sqrt(guest_df$Freq[match(V(gdf)$name,guest_df$Guest)])

# Determine edge width by number of cooccurrences
E(gdf)$width = E(gdf)$Cooccurrence_Count

# Color edges by "Cooccurrence_Prob.extreme" and "Cooccurrence_Prob.extreme.type"
library(RColorBrewer)
my_blues = colorRampPalette(brewer.pal(9,'Blues'))(101) # less than
my_reds = colorRampPalette(brewer.pal(9,'Reds'))(101) # greater than
get_color = function (extreme,type){
  if (type == 'less'){ #blue
    my_blues[round(101 - 100*extreme)]
  } else if (type == 'greater'){ #red
    my_reds[round(101 - 100*extreme)]
  }
}
color_vec = c()
for (i in 1:length(E(gdf))){
  color_vec = c(color_vec, get_color(E(gdf)[i]$Cooccurrence_Prob.extreme,E(gdf)[i]$Cooccurrence_Prob.extreme.type))
}
E(gdf)$color = color_vec

par(mai=c(0,0,0,0))

# Plot1
plot(gdf)
View(df_sub[order(df_sub$Cooccurrence_Prob.extreme),])

# Plot 2
plot(gdf, vertex.color='gray', vertex.label=gsub(' ','\n',V(gdf)$name), 
     vertex.label.color='black', vertex.label.family='Helvetica')

# Plot 3
plot(gdf, vertex.color='gray', vertex.label.color='black', vertex.label.family='Helvetica')

