-include .env

.PHONY: all test clean deploy deploy-sepolia deploy-local deploy-zk deploy-zk-sepolia \
        fund fund-local fund-sepolia withdraw withdraw-local withdraw-sepolia \
        help install snapshot format anvil zk-anvil
		
DEFAULT_ANVIL_PRIVATE_KEY := 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d




# ==================== 环境检查函数 ====================
define check-env
	@if [ -z "$($(1))" ]; then \
		echo "❌ 错误: $(1) 未设置"; \
		echo "请在 .env 文件中设置: $(1)=值"; \
		exit 1; \
	fi
endef

check-rpc-url:
	$(call check-env,$(NETWORK)_RPC_URL)

check-private-key:
	$(call check-env,SEPOLIA_PRIVATE_KEY)

check-sepolia-env:
	$(call check-env,SEPOLIA_RPC_URL)
	$(call check-env,SEPOLIA_PRIVATE_KEY)

check-arb-sepolia-env:
	$(call check-env,ARBITRUM_SEPOLIA_RPC_URL)
	$(call check-env,SEPOLIA_PRIVATE_KEY)

check-zksync-env:
	$(call check-env,ZKSYNC_SEPOLIA_RPC_URL)

install:
	@echo "📦 安装依赖..."
	forge install --no-git https://github.com/OpenZeppelin/openzeppelin-contracts \
	forge install --no-git https://github.com/cyfrin/foundry-devops \
 

remove: rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules

anvil:
	@echo "🏗️ 启动本地 Anvil 节点..."
	anvil -m 'test test test test test test test test test test test junk' \
		--steps-tracing \
		--block-time 1 
	