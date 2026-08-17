-- generate.lua — Rogue TBC All-Specs HUD (v55).
-- Reproducible lineage build: start from the committed v41 snapshot, then replay
-- the reviewed v42 through v54 Lua migrations in order. The snapshot lives
-- inside this script so the class still ships exactly one importable all-specs.txt.
--
-- v54 replaces the 100x100 concentric ring cluster with THE SILL: a 102x37 instrument
-- strip of four stacked 100px rails — threat, health, energy, combo — parked under your
-- character at absolute (0, -110), where ONE PIXEL IS ONE PERCENT. The five combo pips
-- move in from their own 172x14 row. No aura is added or removed; every region in the
-- strip is a v53 aura that changed job, so all 58 uids carry across untouched.
--
-- The >=80% threat alarm is a 108x43 quad drawn FIRST, under the plate: Square_White_Border
-- is FILLED art, so the only way one region can read as an edge is to be bigger than what
-- covers it. The canon below asserts both the size and the draw index, because dropping
-- either turns the alarm back into an ADD red wash over every readout.
--
-- The RING CANON that guarded every earlier version (orientation == "CLOCKWISE",
-- width == height, Ring_20px art, the annulus radii) is REWRITTEN below to the RAIL
-- CANON rather than deleted. Those assertions are the reason a geometry change in this
-- pack has never silently shipped wrong, and a redesign is exactly when they matter.
math.randomseed(20260809)

local dir = (arg and arg[0] or ""):match("^(.*)[/\\]") or "."
local PACK = dir .. "/all-specs.txt"
local BASE_V41 = [[!WA:2!TZ1AWTX11zVgYpeKDSi1dhllBdlhjlQijdasqqQAPeaqqrsbccTaKIIsoelWUa7sUy3v7UGKqTPTMXXrXj2oM1jnntsthoDA)rZ0FWFKF0j9rut90MM2Eg2mTRBsAtvCtAMoTDI6R00NN7D3fpibFkAXi3(dTC37(8E)(oF3Z5CpqmJ0QbB7Nm0j93APw5BL)Ap(I54YpjVUQwmvzv9b84Xtkp(pziTwZRQyQRkllWhtusMxxqzSfzvlwwW3j8fTCHcg3W9OiYc6MgAT4EmRGHAz98cgvV(u6Q5R7cIPQkZRoTIXnYPQZlOh15tqB3rLLU6v5059LbVetjnwJ8CYcEYzFDI6vgcFXcMFT7FboL8IQ6PuLumZflEYmXzN3(IslDvH7zodb5c0tcp0c2TB3)yyy8SGKsbv9sCMsQkExKRSj(GgsJCKHxDU80D6K1WKt30BUcsksgIEJI)X07SM6sflkOBCGJO7S7lYQWvsWWBuZkAcSCL15coRHMGSC)8gEVHr5CctjOyMghWKMzHXJfjDMXtNjcBMQNkLUaEk20PINiX88c5WRmd(O07lEIu9oCcw6fLRpboztXOLXVICAYCve0NRSIZNGxNEy)k4qJNBIDAbDfo5rWVtSRCj9zSh0yMJtrYUx3jS)EVUaNHqAtexlAkEFWbJQOQiSip2bixX4KUJUHaYc4nMLCPKpk4zIwItsPx4K4napd4hcabX)(WlTLdjXRTpB4ot0yuoISV0Ac5nYHpXcsf9UqbDCCdF)CMCEUPnA2lPjY7jx6ySXJNCEt18tz3lU)u7lyzj(fA3yQoLVs)d1wW2UUDV2UZTZ5XXtwHIuqCED6oKNeBrD1YAZt6gs2iCuzvo(EJAG0K9ZwQmYY8gfbS87hI5LnVmNHbzVCMiVtXKSRdVkoFrbTwsFLYC6c(6Tm2FUGOKPqR5)Lo(1Ec4URA5aEgtB)Um90Ys5f8XPW7RhCNBw1cPSMzzDb3HOt4RhboE5k(qgRHQsTM7vcVZliWnPIGHHwRUn3NqjvDDrUIcWobVWU8aTape8aIWd(amW7c3D33dShVqRu2oSxVWX8a7dXCVWd7fE3EHh5ahboWlcpQxeYEm4X9cpb4dEs4qWtbVh4WWrGNgok0Mx44mW79sqiVWjieMLc6TVUObWoGUrWd60deg6kNgo6HgLDaNAbnbTrdWFE(EAVD4z3jCAVWzG3h8(9cr6fIsg4HEOBJt32lD7zH(U2tnVecNPPsmh8UGK4B4bPD7fZ7ORKEAjnHSx39qcYj24aqsCa4xH27jDD3UmosGJcxNyetnHL4now0qbchiANHd3boEDZYgcXNbLisBBHNLoI1M3f4LmMOSckDmLqqozzTw4O7NX2aDqvEHVWDHJL3CsbbTie2MjlXmtKaCOrVbNjXUd)kp9P(ZwSOS609QlCLYck5RKAh(pzWqWb1r(n5elq2mQJf9SKdi08fZv20uvzi0AbfhMN0CcQH9(Ox)fDvaihuvO3Z1XUZzDBrKEY0u92OKDfPFizeLYtPFEONpHeUFl0xquBn5RThTwnfMXCCdro(AFAZrBJS5qhgf2R7kQjeFd7wDLQJgz4mdPThAJOQSkrRk)fK4rDVi4H3KEcuRuGN24ZVOTQHBN760ZprzdtPcvWHvDvtCind2y0KdLmU9qi5AMNEH5Romy)PwaNVtB39QlDvFNVmhprxYxMmn03CFtlsBBAS)FbDoTzVGZolw95qfWhA4mj6pzCN(EDZxD9(tMmo74rhktMHgS2nrM46XC6tJ2qFAkjdPCYczlSOTu04Q2N1r3FCIwMhh5qN(fD41Pf3B39Yfq7bOp4GZHJh2nLtuqQOO55HiJmhYjgNkdM1XMl(rYziPuuwGLDOZoCCi2(HxoRJTPTD6zIsSiJEvv1sejW2jIpOXoQCOTxxJqco0JKbh(HGMnVswQQarFOFh1fISbQEuN6YsA5HxwlD6HDAct48enUtTW0JLpGC)HVAHOtRlPqM4qqKLtwtKZdC8JVd49FGJWMxui)K9chWZStXPlr(AUHWmAs2t6LrQKWHu1o0ZEA2P4Kll0Ai98ICkffW57HpD2z1qFuqxDQqMR5KbojXiyw3(xw2AeQR9uqQguMGZNfyBIe0x0vcshFcdPixjRTweo7JErbtIG0izH0xnAGU7O9OD1z7DJB6WpBGabd3oDBh0THyd2zxDgMOOtLX17lc7GOZder8laJcxKQ(aJr1BGlrLzGl7kTaph8byGXHSa3(GCmqEANa4fbbpqbrOOhqSfqcT0HjyGjr7zq2EQLsGcOcAWvEEqNbmWNTjugFGtbtB)mMbQaxLb(jHFk4dc)0Wpd8Zcp)JbZYaFOSfGxGb(WEGx0(r9rYcxJqkHpk8seEi8XQX)Gpo8YnJ2bVc8QlHWbFIgixdCRqUGxZHynj3fzLWjGnMOp4NteEDKojZqMP6ZMf(CBseh(fDWA4ZxdMd2vGUiB6gr12d1oDBhSbd1EhDJiC3D2fBWWb6Qgod)QRmcpWTccBS5r4hcE(N0gH3I4lp8Tr(Y52s4ldXNPJbNQJEkREfx(Yj2C0LvYhfi9ySThiy7Dq3gIUTt62W0TDrOiJ46EY)3wdiXwcModFSoBlahghtuxm9dV1GPF(Qy6aSb6muGaSbc3EhHPB7IkS3rv08)3EFRLBm4wc34Obp3vKgBaJPKNEf4g(NJtpVTh5VW(bpdOTNQriQ0JVb7pD6(tE2AHhkPPAykun9j9kGEnwlOY4tXrcjMKvLsAM0qaXpJh8lpBrDjEIRNhIThNG)MfDSiTgxEHnvaGlGU0uUKIZdaPBB24arVWKkQapKUHjhjGigs0ERsyE1IMw3oNfczHwYz7WmgUlRb5l6bjr8IbecN568vu4kjLNgRpg8lRSujjZDf1qv3e)iogz(6DIG)nqVuXVafZEXWZu1ZXgPN(ho98fWG5JjPNhDrMeiAsm6ux(X9GW8CKHvAeh7IqIMLgxbo(ZGiVEBtmGyhtyOvP9O4BF6dnCQC6C8sLnEHhGQbGSG94Dw0N6eKpjXR9EGumoKI1RNclI9F0TvJ0IQtpKYIg0)mi6pc6uE9tlqCH4yqgy4AUhSkI)hB5YfSPWyRKRjzqoDGq2BrXJSuXJSvfpwDd0cvnqNNgrHAPCCMU2NnyY2mJvCydTvrdv0CnjIcU4XVjLcwaoyonDbmeiiOoj3udv2Ks1o59nRBcScsEsV5cgyq8c5uXGJl1mR6RTBY(lAI0mdzs0IO1Jwlg4XK4HY42m((YJXvIpJGWFXC0CssJ629cPrnNJ2EfsFOd41zGVrRbATc)oBDgM5ObHqUJzDVdAyw0BiR99nJ99DY7BrYzQ(bLLEH07pB9so557UsxrYiFEbnIKZXziutsAiijhSFKNR909tYdyb0q5YKJnUmxojzjZkJRtKrg3GKzkE8FWNLOyTojM)6iX8tHroAdNYQfHNqFCI8v8EW(Bi4WZhJEgFjWt9KSPVakRnlVGH5WksMWrjjCy8si1LmwKLEK7jZoRB7SPIWYErK5A)UG)E0i4FW(Pd)JuI9paj83ml8pLf(NH)f7l8ATWIJz5NmkjXbATqEYffue0LYBB2KDXgoCbBRiwbo(ke7N5O57jjxjH7p8VgCqw6H2ZrR9iUPRMi4wePDg(okn)pTPThY7rGKqOXR(aYUisjLt7EOURyofWRErObRwRKMqDrvDbvmAvuLbB322Dohsq(jRZhUVTwR2SqN0kHJXs51ozbAINuvoQzB(0fmlRR47OMxkWZ5tv3N5Lc(CTrZ)O5LA)58jOWVo9d8pVrzGUcsONbAIkWTthcNc1uUr1XXjviHD7mJXY1vMV2frW0nIkZVLRkd8MedEhPf4BaFtSHV1kRJa)LWFfEQVn9M(RHBaFNMigaVf83aF3SW3Z1Gh(BZcF)gmUlfzWZoWWhnqFjNPMXn83P12kzspnhYEu1hpViNSmjHfexpw3g1Fa0(5nWV7NMoBdL5jICytT8OG9H12Dg6r(slzwMkTIC0Bu7QOgVZv9oouy)uUD1ggNKZeoC62dDMttO2Zx72qxFTj3udy4Ff(3GFyw4Fh(r0P0(pERRIFu)NoEk)Fb)3zH)hwQRqwmmedilM721EXIXt2n88DlLK3rOvIKV20slM7DLPIwm3h2x2imWF7Tzg45ehEMWdOC0EmgRbg4tT6tQuGGo3cCpKPKxqXuKUyxhkK)QU3qu9FCQFuJtwcmcSBlY3WDKvB)nCCvQxRp7Qs0U)9(5wgtt3Xl7TEUgf8jBc7zdt1ErxQM1QY2iDOncD73zBMUnH)csYgHhTlUknq3wMpmunDNSX78hu7J3XhMgxgUjQToAeNsu9rt(UVanV5GnV52BEZD08MdD9QRqoNUXsxCUR8JDRn39w)AZrd85uleAKU1ZDr)bcYhAdTSC(GxlcDjAkRlqwneYIEPT3yjImyQmdfnrKyNlsp90FM(hjEdrVVsbeKZE5BerjecEg0JTbfzilxjjDDvDCeDNWz0DELATGo)Mh9)ry8QbOnxoz0JhYhcB0eXt2dfjo1cXsyM4QH7nEBXkB3)Th)F3uiGQi9DjksSAQtlO3AGBq)B9tJr9oJ2ko)iBkYouybHQ5Ontw88D6MwNhffp2B2fREpKtMTME0NYv9dNQDVKzf9ftKJugcO3QgMs5nQpTF2pRLQ(GAoix419CRWfSyoaLE6Wfagc364Y7WI5WArQzggHNFi0oKSM0rilt6LhedIG7YzSbbJlBV(4JtxA8XTxHWtAwKdEPwil)c8j7foW9aFQzLuSJtGSAlN(0WNMb(filXITL7NbEDIjss4EPKklMN0I5qRlsJfZtrjmivjenW1URg(6EXt(ESPmyxYI5imwmpTfZrD4e8jtgXuQVrcNzIvJtyXCSwdAX8ErsGfZXr03I5eUqVfZjxcMBX8mnhOTy8F7cvF0MGQp7DthccSeuXIj4Bt4b(y6MggHRhwRbA0NA6RuQ)r9hs5QRfA0(DuOXbBcAWC7fmOcPDsTl831AIeLgBmrdDXrgCYPxlKOJ7OqIhRjiXz3gqIoSrI1wHsnrQzkwXWF)(5xlKi0DuiXJ3eK4L3SibXfq0ZkBxn98s3OwjtrciO6HXve0lwP6H2r4QT3gp2xVYCgI1kBX4tjz4JuamvtuF600JR5my1lb3ywxs(txTXL6uyJfSfT)04MU2MDs0I5jwIxI3lYgvIzKJpfBxT1Bf4z3163lr)ZBOXPpjnD677609Tl1LrzOlIX38UOvYf9eSU(XP1sdhtCOduGxr0M2xhRTX1iTbs7gNEtlZS6ktiYqjIAZMJZPwsRLF8WD56D6LeRVtDrg40NA)WbxGusz49no(VRTFAcZ029HBiw1dF4ns(Z08xT8Qg3UwwBms4X5fYlvItECnDChd6QvuFk3wWUeKy7)S9LrRT14zPRwwHNwqOSfKvv1Hpuw45FeywgTdVg3PDJ5swUuob9PWiBDlGj7QCkioCScX6(yRlH0BqhRJ66LFqmcdTDJoAhHNugyc8c8dYnJ4njL4CrAVOATNrJ)EtBwuV27sFHskIyujoaoKenFwG(v2NepVGcBY4JeNDok1YqcdmHcb2CghNO1oAn3TJXHHaOueJM8Yd3)jQD0jstUbsSmL6wwk8ODNCAbNxdTsUqT)dZgtwGtHAZ(QmS0tk6gXVftyI9mkD)AFfImHTvzTkdKefEQdExlOQlHOj1QB((gIT)XgkzMij2aAYH8En)wmV)9zXeHHoyap4xIk5zXefNFlwD2XFX6npPZzHZxDFoMOu7tIz6TW8vwm9uVHSftC3KBZqmCTy61XC1I5SBbP12IzaBZe0EHW9TygYIj1TeF3I58wmSwmPXp2m1OX3cc8wmdls83yK6P0wmxWIzulMlAXmgTOgo1cf8pYe9owYPpFhtBX8bonD65XjCllMlzXCzlMS1XT6QoU1RI9BUQCkIZU5SyYVbyq7TEgezkIp7DVC(tYLYg2fLc8azRsFEOQjBEvOd2Q40zDP5mB50cBX7RF4QP3UQUT2XxMyyTCG3e54MYN0EYv5Hy3GftY1I1Tk6Z1EA1u1Tys82l)CRqMTgrLOIupd1MbIC0XI2t6eJ0v3dgiDJCukjSEcA3ni(vpbfz7Um0JzZq9qyOpiHHEgKHswEdkhDaAAg70jE2pdYEQE5SCfXzBC50ECU(QbbhiO9w77YrKeJGyh7YnecYckSaDXbvOL0WkxPl6oxbU)rG3x2O6Cs8lnidYxO9gAe4vJZaTJAiqdwNanModxND22mkxmrQMeOrY6tyVfJ3S1BTrgO6YpnD5VlNL7PzwElnWHLw9nJ4Ki6NbEZ5Pl9DQYYgcUzLEzLIdfsp1kezT2P2CjVYoRvh2UaoOCocgDpBYO8ClJc7mtvfcWPcBASENF4Zpv0yZKisLWRqSEVTpz5wuWD)enbw(c2z8qdEPNCJeD3MhcCY4bvrFDIa9voFI2p7WJY2rI7WrGNTjiWbVLqGDElAe4znh9hLBuHWdWfom75xTCDylbTSuDyXCSd1EO6qJT(KDS8LklkD5(EZCgIOM8KndDkuvvZ9EcI3d8MrlWXlqHQtVQglh(2duvVXYAJudYviFf2yxyWUf2Kivh(VnJuwmMWBAXuE9HrwmtrU6PPa0zwvBPnma5h(sKQb9a1s8eo1KMDLDM3OAHDga(Y1QOt46BUub97ElvaNWxb73)ER)Y2eEJSqlrteV3mKCD97VZQLQj8hqY11xDxWFOtHz(TidIFn4pc(JxwXxEFKr6)KD5oyFQfegmZWgNpZO5N4OWIKyt(tRVklHVUy1AW((wRIRCEsbGftwvrWi7kwJ9NInOF)(dZgSl)D3oBhb7oCNB26QFP1tvi7f18TT6P6rwZ6PkYwvruBXuHYREdAfaqS0(UzjvaWBzXOs5peDUq0Ye47LYtaCxKB9DS377NTzfxWBqRRaxB2xNwbbToZpG8iATcd951vJ1rqe76iGBQIHffgONjcj7wi2l53PZZqio5bp)iTdyBZfRhYVozYpVDozskAzlBiQ9W1DUOYO8SVELlRRxXnrV0tetvMhpRQkFdnNMwvcgMcAUvSnT5u6cAC2LMQ27UX2lHEHANJf3FIV0Z4uakU5FM22iCKFn6ApA9FgYQCt6tTG7l(M1DUZjLFYgU)0A6KsjF3110zvlxuOHwIIde8n0IDbOVN6APhjsLSMVw1NF8DqT3qRy0AVHjbw)cueZzIrKJyZ6uPHwVi7AZ7L0s0MictO9mrz(RlsuQiItNAbX2u7QTustkumhrNIQi7kuD)1juHYZHQwEhe1muKZwEcyi1efkpTUk)76ktjQwve5P5Qy4uVsH(IlRELU5s4WRR6wIuA2o)pTq21QaMwRFljRUuZ6Pg5iDRMj686ECRAjrCe9(RP78HU1(1B4iAm0mtgRZyJwym)tuxXh5ovogp)8QkULa8scQploD(LiQlV3lTjXwlMFohmTZqldtVE9ApRla1I5t(Jdaj2x2qa5lSLaKxOuXjdPh4ONTRUBoqAX8Z)2iagMBza481MJ4oj4d7jBi47dVLaFJeQ7k5fJnHuHZUDaFVYxD5WxT5YVtc(WEYgc(EXTe4ZS)OJy23asSML3wS(Kwg8TqD(CDhL5N0gd)(iBj43OXvZBQmGMSXeBl4xXLHFl2GVX3rHGf3yi412sqqjw5Rin1vvdK(cBhiytkIElMh(htGTnEOURiy9r3saRRety02kfZOp1TdWAhMldRYzhB5McVUf(FsGwhBtNNJfTlILmdLIMOPNFFV9KZJvKi8sBnETQl0T)Yti2J(f3oSAR8dxgtqB3lnNcVZZi(JTLGDP6p8rdpXydfsqyBa74vwg0fLKXN35HwF8Te0Q7G8tAonBFIX2oS0m)nwUKRD64UTl5E2BHAA6x(2Vo7lV1yRoqxtQNj4eMjNC7ycx1L)BzLM51B7GF87Sa)xzlb8lWwCO05p3mPNSY2a4)wZUCWNMK935Pu)QBnXIw6c9KQp(KjYSDyR2KF35wm7(DEy1NylbR6VJOxz4eNBQlKk32aw91NCzy1SURn1TBP1dfn0DwARV2wcbiOEMocw4CC9mDPnbbO1P2Xh8)n]]

local function read(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local value = f:read("*a"); f:close(); return value
end

local function write(path, value)
  local f = assert(io.open(path, "w"))
  f:write(value); f:close()
end

local previous = read(PACK)
local savedArg0 = arg[0]

local ok, result = pcall(function()
  write(PACK, BASE_V41)
  for _, patch in ipairs({
    "patch-v42.lua", "patch-v43.lua", "patch-v44.lua", "patch-v45.lua", "patch-v46.lua",
    "patch-v47.lua", "patch-v48.lua", "patch-v49.lua", "patch-v50.lua", "patch-v51.lua",
    "patch-v52.lua", "patch-v53.lua", "patch-v54.lua",
  }) do
    arg[0] = dir .. "/" .. patch
    dofile(arg[0])
  end
  arg[0] = savedArg0

  local final = assert(read(PACK), "replay produced no all-specs.txt")
  local tool = dir .. "/../../tools/tbc-weakaura-creator/scripts/wa_lib.lua"
  local toolArg0 = arg[0]
  arg[0] = tool
  local W = dofile(tool)
  arg[0] = toolArg0

  local transmit = W.decode(final)
  W.verify(transmit, final)
  local cont = previous and W.uidContinuityStrings(final, previous) or nil
  -- No allowance list: v54 removes nothing, so the strict default is back — every uid the
  -- previously shipped string carried must still be here, and an id that keeps its name
  -- while swapping uid is a hard failure either way.
  W.assertUidContinuity(cont, "rogue")

  -- ===== THE RAIL CANON =================================================================
  -- Post-build, on the finished string, hard-coding what The Sill IS. These replace the
  -- ring canon (orientation "CLOCKWISE", width == height, Ring_20px, the annulus radii)
  -- that guarded v49..v53. Nothing here is derived from the patch scripts: the string is
  -- decoded and measured, so a lineage step that silently changes geometry fails here.
  local MEDIA      = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\"
  local RING_TEX   = MEDIA .. "Ring_20px.tga"
  local SQUARE     = MEDIA .. "Square_White.tga"
  local SQUARE_BRD = MEDIA .. "Square_White_Border.tga"
  local SILL_X, SILL_Y   = 0, -110
  local RAIL_LEN         = 100          -- one pixel is one percent
  local PLATE_W, PLATE_H = 102, 37
  local RIM              = 3            -- the alarm sticks out this far past the plate
  local ALARM_W, ALARM_H = PLATE_W + 2 * RIM, PLATE_H + 2 * RIM
  local GROUP  = "Rogue - Player Sill"
  local PLATE  = "Rogue - Sill Plate"
  local ALARM  = "Rogue - Alarm Frame"
  local RAILS  = {
    { id = "Rogue - Threat Rail", h = 4,  y = 15.5, subs = 2 },
    { id = "Rogue - Health Rail", h = 11, y = 7,    subs = 4 },
    { id = "Rogue - Energy Rail", h = 11, y = -5,   subs = 8 },
  }
  local PIP_W, PIP_H, PIP_Y = 16, 6, -14.5
  local PIP_X = { -40, -20, 0, 20, 40 }

  local nodes = { [transmit.d.id] = transmit.d }
  for _, aura in ipairs(transmit.c) do nodes[aura.id] = aura end

  -- Adding xOffset/yOffset up a parent chain only yields a screen position when every node is
  -- screen-anchored, and only yields a CENTRE when every node anchors centre-to-centre. The
  -- three dynamic groups in this pack deliberately anchor by the edge they grow away from
  -- (Alerts BOTTOM/UP, Procs LEFT/RIGHT, PvP TOP/DOWN), so that is the one licensed exception
  -- and the scan below boxes them accordingly. Everything else must be CENTER/CENTER.
  local GROW_SELF = { UP = "BOTTOM", DOWN = "TOP", RIGHT = "LEFT", LEFT = "RIGHT",
                      HORIZONTAL = "CENTER", VERTICAL = "CENTER", CIRCLE = "CENTER" }
  local function assertAnchor(node)
    assert(node.anchorFrameType == nil or node.anchorFrameType == "SCREEN",
      "rail canon: " .. node.id .. " is not screen-anchored")
    assert(node.anchorPoint == nil or node.anchorPoint == "CENTER",
      "rail canon: " .. node.id .. " does not anchor to the screen centre")
    local want = node.regionType == "dynamicgroup" and GROW_SELF[node.grow] or "CENTER"
    assert(node.selfPoint == nil or node.selfPoint == want,
      ("rail canon: %s anchors by %s, expected %s")
        :format(node.id, tostring(node.selfPoint), tostring(want)))
  end
  local function absolute(id)
    local x, y = 0, 0
    local node = assert(nodes[id], "rail canon: missing " .. id)
    while node do
      assertAnchor(node)
      x, y = x + (node.xOffset or 0), y + (node.yOffset or 0)
      node = node.parent and assert(nodes[node.parent], "unresolved parent " .. node.parent)
    end
    return x, y
  end

  -- 1) the strip is where it says it is, by arithmetic on the real parent chain
  do
    local x, y = absolute(GROUP)
    assert(x == SILL_X and y == SILL_Y,
      ("rail canon: the sill resolves to (%s,%s), not (%d,%d)")
        :format(tostring(x), tostring(y), SILL_X, SILL_Y))
  end

  -- 2) the rails: linear, 100px long, square art, never square-shaped
  for _, want in ipairs(RAILS) do
    local a = nodes[want.id]
    assert(a and a.regionType == "progresstexture", "rail canon: " .. want.id .. " is missing")
    assert(a.orientation == "HORIZONTAL_INVERSE",
      "rail canon: " .. want.id .. " does not fill left to right")
    assert(a.width == RAIL_LEN and a.height == want.h,
      ("rail canon: %s is %sx%s, expected %dx%d")
        :format(want.id, tostring(a.width), tostring(a.height), RAIL_LEN, want.h))
    assert(a.width ~= a.height, "rail canon: " .. want.id .. " is square, so it is still a ring")
    assert(a.foregroundTexture == SQUARE and a.backgroundTexture == SQUARE,
      "rail canon: " .. want.id .. " is not drawn on Square_White")
    assert(a.foregroundTexture ~= RING_TEX, "rail canon: " .. want.id .. " is still ring art")
    assert(a.parent == GROUP, "rail canon: " .. want.id .. " is not in the sill")
    assert(a.xOffset == 0 and a.yOffset == want.y,
      ("rail canon: %s sits at (%s,%s), not its lane (0,%g)")
        :format(want.id, tostring(a.xOffset), tostring(a.yOffset), want.y))
    assert(#a.subRegions == want.subs,
      ("rail canon: %s has %d subregions, expected %d")
        :format(want.id, #a.subRegions, want.subs))
    local _, ay = absolute(want.id)
    assert(ay == SILL_Y + want.y, "rail canon: " .. want.id .. " lands off its lane")
  end

  -- 3) the plate, and the alarm rim that must be BIGGER than it and UNDER it.
  --    Square_White_Border.tga is a FILLED square -- the pack's own dark combo sockets are
  --    drawn from it, and the lit pip of identical size hides one completely. So a single
  --    region on that art cannot trace a hollow outline: the alarm reads as an edge only
  --    because it is 3px larger than the plate on every side and is drawn first, under it.
  --    Both halves are canon; drop either and the >=80% flare becomes a full-area ADD red
  --    wash over the numbers, the fills and the pips.
  for _, id in ipairs({ PLATE, ALARM }) do
    local a = nodes[id]
    assert(a and a.regionType == "texture", "rail canon: " .. id .. " is not a texture")
    assert(a.texture == SQUARE_BRD, "rail canon: " .. id .. " is not on Square_White_Border")
    assert(a.xOffset == 0 and a.yOffset == 0, "rail canon: " .. id .. " is off-centre")
  end
  do
    local plate, alarm = nodes[PLATE], nodes[ALARM]
    assert(plate.width == PLATE_W and plate.height == PLATE_H,
      ("rail canon: %s is %sx%s, expected %dx%d")
        :format(PLATE, tostring(plate.width), tostring(plate.height), PLATE_W, PLATE_H))
    assert(alarm.width == PLATE_W + 2 * RIM and alarm.height == PLATE_H + 2 * RIM,
      ("rail canon: %s is %sx%s, expected the %dpx rim %dx%d")
        :format(ALARM, tostring(alarm.width), tostring(alarm.height), RIM, ALARM_W, ALARM_H))
    assert(alarm.blendMode == "ADD" and plate.blendMode == "BLEND",
      "rail canon: the plate and the alarm swapped blend modes")
    local c = alarm.color
    assert(type(c) == "table" and c[1] == 1 and c[2] == 0.1 and c[3] == 0.1 and c[4] == 0.85,
      "rail canon: the alarm rim has no explicit red and would draw in WeakAuras' default")
    local p = plate.color
    assert(type(p) == "table" and p[1] == 0 and p[2] == 0 and p[3] == 0 and p[4] == 0.45,
      "rail canon: the plate is not a dark ground")
  end

  -- 4) the combo lane lives in the strip, not in a row of its own
  for i = 1, 5 do
    for _, id in ipairs({ ("Rogue - Combo Socket %d"):format(i),
                          ("Rogue - Combo Point %d"):format(i) }) do
      local a = assert(nodes[id], "rail canon: missing " .. id)
      assert(a.parent == GROUP, "rail canon: " .. id .. " is not in the sill")
      assert(a.width == PIP_W and a.height == PIP_H,
        ("rail canon: %s is %sx%s, expected %dx%d")
          :format(id, tostring(a.width), tostring(a.height), PIP_W, PIP_H))
      assert(a.xOffset == PIP_X[i] and a.yOffset == PIP_Y,
        "rail canon: " .. id .. " is off its 20px pitch")
    end
  end

  -- 5) draw order — alarm rim first, then the plate, then the readouts, and `c` depth-first
  --    in the same order. Nothing is drawn over a readout, which is the whole point.
  do
    local cc = nodes[GROUP].controlledChildren
    assert(#cc == 15, ("rail canon: the sill holds %d children, expected 15"):format(#cc))
    assert(cc[1] == ALARM, "rail canon: the alarm rim is not the first child, so it is a wash")
    assert(cc[2] == PLATE, "rail canon: the plate is not the second child")
    assert(cc[#cc] ~= ALARM and cc[#cc] ~= PLATE,
      "rail canon: the top of the stack is not a readout")
    local expected = {}
    local function walk(node)
      for _, id in ipairs(node.controlledChildren or {}) do
        expected[#expected + 1] = id
        walk(assert(nodes[id], "unresolved child " .. id))
      end
    end
    walk(transmit.d)
    assert(#expected == #transmit.c,
      ("rail canon: depth-first walk covers %d of %d children")
        :format(#expected, #transmit.c))
    for i, id in ipairs(expected) do
      assert(transmit.c[i].id == id,
        ("rail canon: c is not depth-first at %d: %s, expected %s")
          :format(i, transmit.c[i].id, id))
    end
  end

  -- 6) the geometry proof: the strip against every other element in the pack, with dynamic
  --    groups projected six children deep. A stack that only clears while one alert is up
  --    is not clearance, which is why depth is projected rather than assumed. The box is the
  --    ENVELOPE -- the widest of the plate, the alarm rim and the peak of the pip pop -- so
  --    the proof covers everything the strip ever draws, not just its resting state.
  do
    local DEPTH = 6
    local scale = nodes["Rogue - Combo Point 1"].animation.start.scalex
    local scaleY = nodes["Rogue - Combo Point 1"].animation.start.scaley
    local popX = math.max(math.abs(PIP_X[1]), math.abs(PIP_X[5])) + PIP_W * scale / 2
    local popY = math.abs(PIP_Y) + PIP_H * scaleY / 2
    local sx1 = math.min(SILL_X - ALARM_W / 2, SILL_X - popX)
    local sx2 = math.max(SILL_X + ALARM_W / 2, SILL_X + popX)
    local sy1 = math.min(SILL_Y - ALARM_H / 2, SILL_Y - popY)
    local sy2 = math.max(SILL_Y + ALARM_H / 2, SILL_Y + popY)
    local inSill = { [GROUP] = true }
    for _, id in ipairs(nodes[GROUP].controlledChildren) do inSill[id] = true end
    local scanned, hits, closest, closestId = 0, {}, math.huge, nil
    for _, a in ipairs(transmit.c) do
      if not inSill[a.id] then
        local x1, x2, y1, y2
        if a.regionType == "dynamicgroup" then
          local x, y = absolute(a.id)
          local widest, tallest = 0, 0
          for _, cid in ipairs(a.controlledChildren or {}) do
            widest  = math.max(widest,  nodes[cid].width  or 0)
            tallest = math.max(tallest, nodes[cid].height or 0)
          end
          local space = a.space or 0
          local runX = DEPTH * widest  + (DEPTH - 1) * space
          local runY = DEPTH * tallest + (DEPTH - 1) * space
          if a.grow == "UP" then
            x1, x2, y1, y2 = x - widest / 2, x + widest / 2, y, y + runY
          elseif a.grow == "DOWN" then
            x1, x2, y1, y2 = x - widest / 2, x + widest / 2, y - runY, y
          elseif a.grow == "RIGHT" then
            x1, x2, y1, y2 = x, x + runX, y - tallest / 2, y + tallest / 2
          elseif a.grow == "LEFT" then
            x1, x2, y1, y2 = x - runX, x, y - tallest / 2, y + tallest / 2
          else
            x1, x2 = x - runX / 2, x + runX / 2
            y1, y2 = y - tallest / 2, y + tallest / 2
          end
        elseif a.regionType ~= "group" then
          local x, y = absolute(a.id)
          local w, h = a.width or 0, a.height or 0
          x1, x2, y1, y2 = x - w / 2, x + w / 2, y - h / 2, y + h / 2
        end
        if x1 then
          scanned = scanned + 1
          if sx1 < x2 and x1 < sx2 and sy1 < y2 and y1 < sy2 then
            hits[#hits + 1] = ("%s (x %g..%g, y %g..%g)"):format(a.id, x1, x2, y1, y2)
          else
            local gap = math.max(sx1 - x2, x1 - sx2, sy1 - y2, y1 - sy2)
            if gap < closest then closest, closestId = gap, a.id end
          end
        end
      end
    end
    assert(scanned > 0, "rail canon: the geometry proof examined nothing")
    assert(#hits == 0, ("rail canon: the strip envelope at (%d,%d) overlaps %d element(s): %s")
      :format(SILL_X, SILL_Y, #hits, table.concat(hits, "; ")))
    print(("geometry: sill plate %dx%d, alarm rim %dx%d, pop x+-%.2f at (%d,%d) -> envelope "
      .. "x %g..%g y %g..%g; %d elements scanned (dynamic groups %d deep), 0 overlaps, "
      .. "closest %.2fpx (%s)")
      :format(PLATE_W, PLATE_H, ALARM_W, ALARM_H, popX, SILL_X, SILL_Y, sx1, sx2, sy1, sy2,
        scanned, DEPTH, closest, tostring(closestId)))
  end

  -- 7) nothing anywhere in the pack is still a ring
  for _, aura in ipairs(transmit.c) do
    assert(aura.foregroundTexture ~= RING_TEX and aura.backgroundTexture ~= RING_TEX
      and aura.texture ~= RING_TEX,
      "rail canon: " .. aura.id .. " still draws on Ring_20px")
    assert(aura.orientation ~= "CLOCKWISE",
      "rail canon: " .. aura.id .. " is still a clockwise progresstexture")
  end

  return { encoded = final, transmit = transmit }
end)

arg[0] = savedArg0
if not ok then
  if previous then write(PACK, previous) else os.remove(PACK) end
  error(result)
end

print(("OK: %d auras (1 top + %d children), %d chars -> all-specs.txt")
  :format(#result.transmit.c + 1, #result.transmit.c, #result.encoded))
