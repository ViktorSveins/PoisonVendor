local addonName, PoisonVendor = ...

PoisonVendor = PoisonVendor or _G.PoisonVendor or {}
_G.PoisonVendor = PoisonVendor

PoisonVendor.name = addonName
PoisonVendor.state = PoisonVendor.state or {}
local state = PoisonVendor.state
state.merchantOpen = false
state.currentRows = {}

function PoisonVendor.TryExecutePurchasePlan(plan)
  if type(plan) ~= "table" then
    return false
  end

  if type(PoisonVendor.ExecutePurchasePlan) == "function" then
    return PoisonVendor.ExecutePurchasePlan(plan)
  end

  return false
end

function PoisonVendor.RefreshExpandedBatchPanels(collapseOnly)
  if type(PoisonVendor.UpdateVendorPanelExpansion) == "function" then
    PoisonVendor.UpdateVendorPanelExpansion(collapseOnly == true)
  end
end

function PoisonVendor.RefreshCurrentRows()
  if not state.merchantOpen or type(PoisonVendor.BuildCurrentRows) ~= "function" then
    state.currentRows = {}
    if type(PoisonVendor.HideVendorPanel) == "function" then
      PoisonVendor.HideVendorPanel()
    end
    return state.currentRows
  end

  state.currentRows = PoisonVendor.BuildCurrentRows() or {}
  if type(PoisonVendor.RenderVendorPanel) == "function" then
    PoisonVendor.RenderVendorPanel(state.currentRows)
  end
  return state.currentRows
end

local events = CreateFrame("Frame")
PoisonVendor.events = events

function PoisonVendor:OnEvent(event, ...)
  if event == "MERCHANT_SHOW" then
    state.merchantOpen = true
    PoisonVendor.RefreshCurrentRows()
  elseif event == "MERCHANT_CLOSED" then
    state.merchantOpen = false
    state.currentRows = {}
    if type(PoisonVendor.HideVendorPanel) == "function" then
      PoisonVendor.HideVendorPanel()
    end
  elseif event == "MERCHANT_UPDATE" then
    PoisonVendor.RefreshCurrentRows()
  elseif event == "MODIFIER_STATE_CHANGED" then
    -- no longer used
  end
end

events:SetScript("OnEvent", function(_, event, ...)
  PoisonVendor:OnEvent(event, ...)
end)

for _, event in ipairs({ "MERCHANT_SHOW", "MERCHANT_CLOSED", "MERCHANT_UPDATE", "MODIFIER_STATE_CHANGED" }) do
  events:RegisterEvent(event)
end
