drop_dup_uuid <- function(df, report = NULL) {
  
  dupes <- df %>% 
    group_by(uuid) %>% 
    filter(n() > 1) %>% 
    mutate(n = n()) %>% 
    ungroup() %>% 
    arrange(uuid) %>% 
    distinct()
  
  df2 <- df %>% 
    filter(!uuid %in% dupes$uuid) %>% 
    bind_rows(select(dupes, -n))
  
  if (!is.null(report)) {
    
    
    if (nrow(dupes)) report$add("DUPLICATE_UUID_DROPPED", dupes$uuid, "uuid", paste0(dupes$n, " rows"), "1 row", message = "UUID deleted when all values identical")
  }
  df2
  }