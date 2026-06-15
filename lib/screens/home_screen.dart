import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/balance_card.dart';
import '../widgets/filter_bar.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'بحث عن عملية...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
                onChanged: (v) => context.read<ExpenseProvider>().setSearch(v),
              )
            : const Text('تتبع المصاريف'),
        leading: _showSearch
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() => _showSearch = false);
                  _searchController.clear();
                  context.read<ExpenseProvider>().setSearch('');
                },
              )
            : null,
        actions: [
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => setState(() => _showSearch = true),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<ExpenseProvider>().loadTransactions(),
        child: Consumer<ExpenseProvider>(
          builder: (context, provider, _) {
            final transactions = provider.filteredTransactions;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: const BalanceCard()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: const FilterBar(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'العمليات (${transactions.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (transactions.isNotEmpty)
                          TextButton(
                            onPressed: () {},
                            child: const Text('عرض الكل'),
                          ),
                      ],
                    ),
                  ),
                ),
                if (transactions.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(
                      isSearch: provider.searchQuery.isNotEmpty,
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final tx = transactions[i];
                        return TransactionCard(
                          transaction: tx,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddTransactionScreen(transaction: tx),
                            ),
                          ),
                          onDelete: () => context.read<ExpenseProvider>().deleteTransaction(tx.id),
                        );
                      },
                      childCount: transactions.length,
                    ),
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  const _EmptyState({this.isSearch = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isSearch ? '🔍' : '💸',
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'لا توجد نتائج' : 'لا توجد عمليات',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            isSearch
                ? 'جرب بحثاً مختلفاً'
                : 'ابدأ بإضافة أول عملية مالية لك',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
