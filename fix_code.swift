    /**
     * 根据搜索文本和分类筛选历史人物
     */
    func filteredFigures(searchText: String, category: String) -> [CommentHistoricalFigure] {
        var filtered = availableFigures
        
        // 应用搜索过滤
        if !searchText.isEmpty {
            filtered = filtered.filter { figure in
                figure.name.localizedCaseInsensitiveContains(searchText) ||
                figure.field.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 应用分类过滤
        if category != "全部" {
            if category == "最近" {
                // 获取最近使用的历史人物
                filtered = getRecentlyUsedFigures()
            } else if category == "关注" {
                // 获取用户关注的历史人物
                filtered = getFollowedFigures()
            } else {
                // 按领域筛选
                filtered = filtered.filter { figure in
                    figure.field.contains(category)
                }
            }
        }
        
        // 将相关角色排在最前面
        let relevantFigures = filtered.filter { isRelevant($0) }
        let nonRelevantFigures = filtered.filter { !isRelevant($0) }
        
        return relevantFigures + nonRelevantFigures
    }
